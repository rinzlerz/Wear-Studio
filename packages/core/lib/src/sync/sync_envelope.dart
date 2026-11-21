import 'dart:convert';
import 'dart:typed_data';

import '../json_utils.dart';
import '../model/watch_profile.dart';

enum SyncPayloadType {
  profile('profile'),
  ping('ping'),
  pong('pong');

  const SyncPayloadType(this.wireName);

  final String wireName;

  static SyncPayloadType parse(String value) => values.firstWhere(
        (t) => t.wireName == value,
        orElse: () => throw FormatException('Unknown payload type "$value"'),
      );
}

/// Wire wrapper for everything sent over the Data Layer.
///
/// `revision` is a monotonically increasing number chosen by the sender.
/// The receiver ignores anything not newer than what it already applied,
/// which makes redelivery after reconnection harmless (PRD FR-001).
class SyncEnvelope {
  const SyncEnvelope({
    this.protocol = protocolVersion,
    required this.type,
    required this.revision,
    required this.sentAt,
    required this.payload,
  });

  factory SyncEnvelope.profile(
    WatchProfile profile, {
    required int revision,
    DateTime? sentAt,
  }) =>
      SyncEnvelope(
        type: SyncPayloadType.profile,
        revision: revision,
        sentAt: sentAt ?? DateTime.now().toUtc(),
        payload: profile.toJson(),
      );

  factory SyncEnvelope.ping(String pingId, {DateTime? sentAt}) => SyncEnvelope(
        type: SyncPayloadType.ping,
        revision: 0,
        sentAt: sentAt ?? DateTime.now().toUtc(),
        payload: {'pingId': pingId},
      );

  factory SyncEnvelope.pong(String pingId, {DateTime? sentAt}) => SyncEnvelope(
        type: SyncPayloadType.pong,
        revision: 0,
        sentAt: sentAt ?? DateTime.now().toUtc(),
        payload: {'pingId': pingId},
      );

  factory SyncEnvelope.fromJson(Map<String, Object?> json) {
    final protocol = readInt(json, 'protocol');
    if (protocol != protocolVersion) {
      throw FormatException('Unsupported sync protocol $protocol');
    }
    final sentAt = DateTime.tryParse(readString(json, 'sentAt'));
    if (sentAt == null) throw const FormatException('Invalid "sentAt"');
    return SyncEnvelope(
      protocol: protocol,
      type: SyncPayloadType.parse(readString(json, 'type')),
      revision: readInt(json, 'revision'),
      sentAt: sentAt,
      payload: readMap(json, 'payload'),
    );
  }

  /// Decodes UTF-8 JSON bytes. Throws [FormatException] on bad input.
  factory SyncEnvelope.decode(List<int> bytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException catch (e) {
      throw FormatException('Envelope is not valid UTF-8 JSON: ${e.message}');
    }
    return SyncEnvelope.fromJson(asJsonMap(decoded, 'envelope'));
  }

  static const int protocolVersion = 1;

  final int protocol;
  final SyncPayloadType type;
  final int revision;
  final DateTime sentAt;
  final Map<String, Object?> payload;

  /// The profile carried by a [SyncPayloadType.profile] envelope.
  WatchProfile get profile {
    if (type != SyncPayloadType.profile) {
      throw StateError('Envelope of type ${type.wireName} has no profile');
    }
    return WatchProfile.fromJson(payload);
  }

  /// The id carried by ping/pong envelopes.
  String get pingId => readString(payload, 'pingId');

  Map<String, Object?> toJson() => {
        'protocol': protocol,
        'type': type.wireName,
        'revision': revision,
        'sentAt': sentAt.toUtc().toIso8601String(),
        'payload': payload,
      };

  Uint8List encode() => Uint8List.fromList(utf8.encode(jsonEncode(toJson())));
}

/// Issues strictly increasing revisions, seeded from wall-clock time so they
/// keep increasing across app restarts on the sending device.
class RevisionClock {
  RevisionClock({int Function()? now})
      : _now = now ?? (() => DateTime.now().microsecondsSinceEpoch);

  final int Function() _now;
  int _last = 0;

  int next() {
    final candidate = _now();
    _last = candidate > _last ? candidate : _last + 1;
    return _last;
  }
}
