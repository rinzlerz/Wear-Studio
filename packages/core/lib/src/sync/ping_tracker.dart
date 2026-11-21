import 'sync_envelope.dart';

/// Tracks outstanding pings so a pong can be turned into a round-trip time.
class PingTracker {
  PingTracker({DateTime Function()? clock, this.maxPending = 16})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final int maxPending;
  final _pending = <String, DateTime>{};
  int _counter = 0;

  /// Creates a ping envelope and remembers when it was sent.
  SyncEnvelope createPing() {
    final now = _clock();
    final id = '${now.microsecondsSinceEpoch}-${_counter++}';
    _pending[id] = now;
    while (_pending.length > maxPending) {
      _pending.remove(_pending.keys.first);
    }
    return SyncEnvelope.ping(id, sentAt: now.toUtc());
  }

  /// Returns the round-trip time for a pong, or null if it was not ours
  /// (unknown, expired or already answered).
  Duration? resolvePong(SyncEnvelope pong) {
    if (pong.type != SyncPayloadType.pong) return null;
    final sentAt = _pending.remove(pong.pingId);
    return sentAt == null ? null : _clock().difference(sentAt);
  }
}
