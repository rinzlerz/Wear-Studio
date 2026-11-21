import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wear_studio_core/wear_studio_core.dart';
import 'package:wear_studio_platform/wear_studio_platform.dart';

import '../../providers.dart';

class LogEntry {
  const LogEntry(this.time, this.message, {this.isError = false});

  final DateTime time;
  final String message;
  final bool isError;
}

class CompanionState {
  const CompanionState({
    this.loading = false,
    this.watches = const [],
    this.connectedNodes = const [],
    this.selectedWatchId,
    this.lastRoundTrip,
    this.lastPushedRevision,
    this.unavailableReason,
    this.log = const [],
  });

  final bool loading;

  /// Reachable nodes that have the Wear Studio watch app installed.
  final List<WearNode> watches;

  /// All connected nodes, including ones without the watch app.
  final List<WearNode> connectedNodes;
  final String? selectedWatchId;
  final Duration? lastRoundTrip;
  final int? lastPushedRevision;

  /// Set when the Wearable API is not available on this phone.
  final String? unavailableReason;
  final List<LogEntry> log;

  WearNode? get selectedWatch {
    for (final w in watches) {
      if (w.id == selectedWatchId) return w;
    }
    return null;
  }

  CompanionState copyWith({
    bool? loading,
    List<WearNode>? watches,
    List<WearNode>? connectedNodes,
    String? Function()? selectedWatchId,
    Duration? lastRoundTrip,
    int? lastPushedRevision,
    String? Function()? unavailableReason,
    List<LogEntry>? log,
  }) =>
      CompanionState(
        loading: loading ?? this.loading,
        watches: watches ?? this.watches,
        connectedNodes: connectedNodes ?? this.connectedNodes,
        selectedWatchId:
            selectedWatchId != null ? selectedWatchId() : this.selectedWatchId,
        lastRoundTrip: lastRoundTrip ?? this.lastRoundTrip,
        lastPushedRevision: lastPushedRevision ?? this.lastPushedRevision,
        unavailableReason: unavailableReason != null
            ? unavailableReason()
            : this.unavailableReason,
        log: log ?? this.log,
      );
}

final companionControllerProvider =
    NotifierProvider<CompanionController, CompanionState>(
  CompanionController.new,
);

/// Phase 1 connectivity: find the watch, ping it, push a test profile.
class CompanionController extends Notifier<CompanionState> {
  static const _maxLog = 100;

  final _pings = PingTracker();
  final _revisions = RevisionClock();

  DataLayer get _dataLayer => ref.read(dataLayerProvider);

  @override
  CompanionState build() {
    final subscription = _dataLayer.events.listen(
      _onEvent,
      onError: (Object e) => _log('Event stream error: $e', isError: true),
    );
    ref.onDispose(subscription.cancel);
    Future.microtask(refresh);
    return const CompanionState(loading: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true);
    try {
      final watches = await _dataLayer.capableNodes(WearCapabilities.watch);
      final connected = await _dataLayer.connectedNodes();
      if (!ref.mounted) return;
      final keep = watches.any((w) => w.id == state.selectedWatchId);
      state = state.copyWith(
        loading: false,
        watches: watches,
        connectedNodes: connected,
        unavailableReason: () => null,
        selectedWatchId: () => keep
            ? state.selectedWatchId
            : (watches.isEmpty ? null : _preferNearby(watches).id),
      );
      _log('Found ${watches.length} watch(es) with Wear Studio, '
          '${connected.length} connected node(s).');
    } on DataLayerException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        loading: false,
        watches: const [],
        connectedNodes: const [],
        selectedWatchId: () => null,
        unavailableReason: () => e.isUnavailable
            ? 'Wear OS APIs are not available on this phone. Install the '
                'Wear OS / Galaxy Wearable app and pair a watch.'
            : e.toString(),
      );
      _log('Node discovery failed: $e', isError: true);
    }
  }

  void selectWatch(String nodeId) =>
      state = state.copyWith(selectedWatchId: () => nodeId);

  Future<void> ping() async {
    final watch = state.selectedWatch;
    if (watch == null) {
      _log('No watch selected.', isError: true);
      return;
    }
    final envelope = _pings.createPing();
    try {
      await _dataLayer.sendMessage(watch.id, SyncPaths.ping, envelope.encode());
      _log('Ping sent to ${watch.displayName}.');
    } on DataLayerException catch (e) {
      _log('Ping failed: $e', isError: true);
    }
  }

  /// Validates and publishes [profile] as the active profile data item.
  /// The Data Layer delivers it to the watch now or when it reconnects.
  Future<void> pushProfile(WatchProfile profile) async {
    final validation = const ProfileValidator(
      knownWidgetTypes: BuiltInWidgetTypes.all,
    ).validate(profile);
    if (!validation.isValid) {
      _log('Not sent, profile is invalid:\n$validation', isError: true);
      return;
    }
    final revision = _revisions.next();
    final envelope = SyncEnvelope.profile(profile, revision: revision);
    try {
      await _dataLayer.putData(SyncPaths.activeProfile, envelope.encode());
      if (!ref.mounted) return;
      state = state.copyWith(lastPushedRevision: revision);
      _log('Published "${profile.profileName}" (revision $revision).');
    } on DataLayerException catch (e) {
      _log('Publishing failed: $e', isError: true);
    }
  }

  void _onEvent(WearEvent event) {
    switch (event) {
      case final WearMessageEvent m when m.path == SyncPaths.ping:
        unawaited(_answerPing(m));
      case final WearMessageEvent m when m.path == SyncPaths.pong:
        _handlePong(m);
      case WearMessageEvent():
      case WearDataEvent():
        break; // Not used by the companion in Phase 1.
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
      _log('Answered ping from watch ${event.sourceNodeId}.');
    } on FormatException catch (e) {
      _log('Ignored malformed ping: ${e.message}', isError: true);
    } on DataLayerException catch (e) {
      _log('Could not answer ping: $e', isError: true);
    }
  }

  void _handlePong(WearMessageEvent event) {
    try {
      final rtt = _pings.resolvePong(SyncEnvelope.decode(event.data));
      if (rtt == null) return;
      state = state.copyWith(lastRoundTrip: rtt);
      _log('Pong from watch: ${rtt.inMilliseconds} ms round trip.');
    } on FormatException catch (e) {
      _log('Ignored malformed pong: ${e.message}', isError: true);
    }
  }

  void _log(String message, {bool isError = false}) {
    if (!ref.mounted) return;
    final entry = LogEntry(DateTime.now(), message, isError: isError);
    final log = [entry, ...state.log];
    state = state.copyWith(
      log: log.length > _maxLog ? log.sublist(0, _maxLog) : log,
    );
  }

  static WearNode _preferNearby(List<WearNode> nodes) =>
      nodes.firstWhere((n) => n.isNearby, orElse: () => nodes.first);
}
