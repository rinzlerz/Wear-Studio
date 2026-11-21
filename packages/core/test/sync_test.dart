import 'dart:convert';

import 'package:test/test.dart';
import 'package:wear_studio_core/wear_studio_core.dart';

void main() {
  group('SyncEnvelope', () {
    test('profile envelope round-trips through bytes', () {
      final sentAt = DateTime.utc(2026, 11, 21, 12);
      final envelope = SyncEnvelope.profile(
        SampleProfiles.minimal,
        revision: 42,
        sentAt: sentAt,
      );

      final decoded = SyncEnvelope.decode(envelope.encode());

      expect(decoded.type, SyncPayloadType.profile);
      expect(decoded.revision, 42);
      expect(decoded.sentAt, sentAt);
      expect(decoded.profile, SampleProfiles.minimal);
    });

    test('rejects garbage bytes', () {
      expect(
          () => SyncEnvelope.decode([0xff, 0xfe, 0x00]), throwsFormatException);
      expect(
        () => SyncEnvelope.decode(utf8.encode('[1,2,3]')),
        throwsFormatException,
      );
    });

    test('rejects an unknown protocol version', () {
      final json = SyncEnvelope.ping('x').toJson()..['protocol'] = 99;

      expect(
        () => SyncEnvelope.decode(utf8.encode(jsonEncode(json))),
        throwsFormatException,
      );
    });

    test('profile getter refuses non-profile envelopes', () {
      expect(() => SyncEnvelope.ping('x').profile, throwsStateError);
    });
  });

  group('decideIncomingProfile', () {
    SyncEnvelope envelopeAt(int revision, [WatchProfile? profile]) =>
        SyncEnvelope.profile(profile ?? SampleProfiles.minimal,
            revision: revision);

    test('accepts the first profile', () {
      final decision = decideIncomingProfile(
        envelope: envelopeAt(10),
        currentRevision: null,
      );

      expect(decision, isA<AcceptProfile>());
      expect((decision as AcceptProfile).revision, 10);
    });

    test('ignores redelivery of the same revision (no duplicates)', () {
      final decision = decideIncomingProfile(
        envelope: envelopeAt(10),
        currentRevision: 10,
      );

      expect(decision, isA<IgnoreStaleProfile>());
    });

    test('ignores older revisions', () {
      expect(
        decideIncomingProfile(envelope: envelopeAt(9), currentRevision: 10),
        isA<IgnoreStaleProfile>(),
      );
    });

    test('rejects invalid profiles and keeps the current one', () {
      final bad = SampleProfiles.minimal.copyWith(
        widgets: [
          SampleProfiles.minimal.widgets.first,
          SampleProfiles.minimal.widgets.first,
        ],
      );

      final decision = decideIncomingProfile(
        envelope: envelopeAt(11, bad),
        currentRevision: 10,
      );

      expect(decision, isA<RejectProfile>());
    });

    test('rejects malformed payloads instead of throwing', () {
      final envelope = SyncEnvelope(
        type: SyncPayloadType.profile,
        revision: 1,
        sentAt: DateTime.utc(2026),
        payload: {'schemaVersion': 1, 'profileId': 3},
      );

      expect(
        decideIncomingProfile(envelope: envelope, currentRevision: null),
        isA<RejectProfile>(),
      );
    });
  });

  group('RevisionClock', () {
    test('is strictly increasing even if the clock stalls or goes back', () {
      final times = [100, 100, 50, 200];
      var i = 0;
      final clock = RevisionClock(now: () => times[i++]);

      expect([clock.next(), clock.next(), clock.next(), clock.next()],
          [100, 101, 102, 200]);
    });
  });

  group('PingTracker', () {
    test('measures round trip for its own pings only', () {
      var now = DateTime.utc(2026, 1, 1, 0, 0, 0);
      final tracker = PingTracker(clock: () => now);

      final ping = tracker.createPing();
      now = now.add(const Duration(milliseconds: 120));

      expect(tracker.resolvePong(SyncEnvelope.pong(ping.pingId)),
          const Duration(milliseconds: 120));
      expect(tracker.resolvePong(SyncEnvelope.pong(ping.pingId)), isNull,
          reason: 'already answered');
      expect(tracker.resolvePong(SyncEnvelope.pong('unknown')), isNull);
    });
  });
}
