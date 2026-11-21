import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wear_studio_core/wear_studio_core.dart';
import 'package:wear_studio_platform/wear_studio_platform.dart';
import 'package:wear_studio_widget_engine/wear_studio_widget_engine.dart'
    show PhoneLinkState;

import '../../data/profile_store.dart';
import '../../providers.dart';

class WatchState {
  const WatchState({
    this.profile,
    this.revision,
    this.phoneLink = PhoneLinkState.unknown,
    this.phoneNodeId,
    this.lastSyncAt,
    this.lastRoundTrip,
    this.log = const [],
  });

  /// Active profile; null until one has been received or loaded.
  final WatchProfile? profile;
  final int? revision;
  final PhoneLinkState phoneLink;
  final String? phoneNodeId;
  final DateTime? lastSyncAt;
  final Duration? lastRoundTrip;
  final List<String> log;

  WatchState copyWith({
    WatchProfile? profile,
    int? revision,
    PhoneLinkState? phoneLink,
    String? Function()? phoneNodeId,
    DateTime? lastSyncAt,
    Duration? lastRoundTrip,
    List<String>? log,
  }) =>
      WatchState(
        profile: profile ?? this.profile,
        revision: revision ?? this.revision,
        phoneLink: phoneLink ?? this.phoneLink,
        phoneNodeId: phoneNodeId != null ? phoneNodeId() : this.phoneNodeId,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        lastRoundTrip: lastRoundTrip ?? this.lastRoundTrip,
        log: log ?? this.log,
      );
}

final watchControllerProvider =
    NotifierProvider<WatchController, WatchState>(WatchController.new);

/// Watch-side sync: restore the stored profile, catch up with the Data
/// Layer, then apply newer profiles as they arrive. Every candidate goes
/// through [decideIncomingProfile], so redelivered or invalid data never
/// replaces what is shown.
class WatchController extends Notifier<WatchState> {
  static const _maxLog = 50;

  final _pings = PingTracker();

  /// Serializes profile handling so revision checks and writes don't race.
  Future<void> _queue = Future.value();

  DataLayer get _dataLayer => ref.read(dataLayerProvider);
  ProfileStore get _store => ref.read(profileStoreProvider);

  @override
  WatchState build() {
    final subscription = _dataLayer.events.listen(
      _onEvent,
      onError: (Object e) => _log('event stream error: $e'),
    );
    ref.onDispose(subscription.cancel);
    Future.microtask(_start);
    return const WatchState();
  }

  Future<void> _start() async {
    // 1. Offline first: show the last accepted profile immediately.
    final stored = await _store.load();
    if (!ref.mounted) return;
    if (stored != null) {
      state =
          state.copyWith(profile: stored.profile, revision: stored.revision);
      _log('restored "${stored.profile.profileName}" (rev ${stored.revision})');
    }

    // 2. Catch up on anything published while the app was closed.
    try {
      final items = await _dataLayer.dataItems(SyncPaths.activeProfile);
      for (final item in items) {
        final data = item.data;
        if (data != null) await _enqueueProfile(data, source: 'catch-up');
      }
    } on DataLayerException catch (e) {
      _log('catch-up skipped: $e');
    }

    await findPhone();
  }

  Future<void> findPhone() async {
    try {
      final phones = await _dataLayer.capableNodes(WearCapabilities.companion);
      if (!ref.mounted) return;
      final phone = phones.isEmpty
          ? null
          : phones.firstWhere((n) => n.isNearby, orElse: () => phones.first);
      state = state.copyWith(
        phoneLink: phone == null
            ? PhoneLinkState.disconnected
            : PhoneLinkState.connected,
        phoneNodeId: () => phone?.id,
      );
    } on DataLayerException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        phoneLink: e.isUnavailable
            ? PhoneLinkState.unavailable
            : PhoneLinkState.disconnected,
        phoneNodeId: () => null,
      );
      _log('phone lookup failed: $e');
    }
  }

  Future<void> pingPhone() async {
    await findPhone();
    final phoneId = state.phoneNodeId;
    if (phoneId == null) {
      _log('no phone to ping');
      return;
    }
    try {
      await _dataLayer.sendMessage(
        phoneId,
        SyncPaths.ping,
        _pings.createPing().encode(),
      );
      _log('ping sent');
    } on DataLayerException catch (e) {
      _log('ping failed: $e');
    }
  }

  void _onEvent(WearEvent event) {
    switch (event) {
      case final WearDataEvent e
          when e.path == SyncPaths.activeProfile &&
              !e.deleted &&
              e.data != null:
        unawaited(_enqueueProfile(e.data!, source: 'phone'));
      case final WearMessageEvent m when m.path == SyncPaths.ping:
        unawaited(_answerPing(m));
      case final WearMessageEvent m when m.path == SyncPaths.pong:
        _handlePong(m);
      case WearDataEvent():
      case WearMessageEvent():
        break;
    }
  }

  Future<void> _enqueueProfile(List<int> bytes, {required String source}) {
    final next = _queue.then((_) => _applyProfile(bytes, source: source));
    _queue = next.catchError((Object e) => _log('apply failed: $e'));
    return _queue;
  }

  Future<void> _applyProfile(List<int> bytes, {required String source}) async {
    if (!ref.mounted) return;
    final SyncEnvelope envelope;
    try {
      envelope = SyncEnvelope.decode(bytes);
    } on FormatException catch (e) {
      _log('rejected $source data: ${e.message}');
      return;
    }

    final decision = decideIncomingProfile(
      envelope: envelope,
      currentRevision: state.revision,
    );
    switch (decision) {
      case AcceptProfile(:final profile, :final revision, :final validation):
        await _store.save(StoredProfile(profile, revision));
        if (!ref.mounted) return;
        state = state.copyWith(
          profile: profile,
          revision: revision,
          lastSyncAt: DateTime.now(),
        );
        _log('applied "${profile.profileName}" rev $revision from $source'
            '${validation.warnings.isEmpty ? '' : ' (${validation.warnings.length} warnings)'}');
      case IgnoreStaleProfile(:final incomingRevision):
        _log('ignored stale rev $incomingRevision from $source');
      case RejectProfile(:final reason):
        _log('rejected $source profile: $reason');
    }
  }

  Future<void> _answerPing(WearMessageEvent event) async {
    try {
      final ping = SyncEnvelope.decode(event.data);
      await _dataLayer.sendMessage(
        event.sourceNodeId,
        SyncPaths.pong,
        SyncEnvelope.pong(ping.pingId).encode(),
      );
      _log('answered ping');
      if (!ref.mounted) return;
      state = state.copyWith(
        phoneLink: PhoneLinkState.connected,
        phoneNodeId: () => event.sourceNodeId,
      );
    } on FormatException catch (e) {
      _log('bad ping: ${e.message}');
    } on DataLayerException catch (e) {
      _log('pong failed: $e');
    }
  }

  void _handlePong(WearMessageEvent event) {
    try {
      final rtt = _pings.resolvePong(SyncEnvelope.decode(event.data));
      if (rtt == null || !ref.mounted) return;
      state = state.copyWith(
          lastRoundTrip: rtt, phoneLink: PhoneLinkState.connected);
      _log('pong ${rtt.inMilliseconds} ms');
    } on FormatException catch (e) {
      _log('bad pong: ${e.message}');
    }
  }

  void _log(String message) {
    if (!ref.mounted) return;
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final line =
        '${two(now.hour)}:${two(now.minute)}:${two(now.second)} $message';
    final log = [line, ...state.log];
    state = state.copyWith(
      log: log.length > _maxLog ? log.sublist(0, _maxLog) : log,
    );
  }
}
