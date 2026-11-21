import 'dart:convert';

import 'package:test/test.dart';
import 'package:wear_studio_core/wear_studio_core.dart';

void main() {
  group('WatchProfile JSON', () {
    test('parses the PRD §6.1 example', () {
      const source = '''
      {
        "schemaVersion": 1,
        "profileId": "dedsec_profile",
        "profileName": "DedSec",
        "themeId": "dedsec_green",
        "widgets": [
          {
            "widgetId": "clock_001",
            "type": "digital_clock",
            "position": {"x": 0.5, "y": 0.2},
            "size": {"width": 0.8, "height": 0.15},
            "zIndex": 1,
            "settings": {"format": "24h", "showDate": true}
          }
        ]
      }''';

      final profile = WatchProfile.fromJsonString(source);

      expect(profile, SampleProfiles.prdExample);
      expect(profile.widgets.single.visible, isTrue, reason: 'defaults');
    });

    test('round-trips through JSON without loss', () {
      for (final original in [
        SampleProfiles.minimal,
        SampleProfiles.prdExample
      ]) {
        final decoded = WatchProfile.fromJsonString(original.toJsonString());
        expect(decoded, original);
        expect(decoded.hashCode, original.hashCode);
      }
    });

    test('accepts whole numbers written as integers for coordinates', () {
      final json = SampleProfiles.minimal.toJson();
      final widgets = json['widgets']! as List<Object?>;
      final first = widgets.first! as Map<String, Object?>;
      first['position'] = {'x': 1, 'y': 0};

      final profile = WatchProfile.fromJson(json);

      expect(profile.widgets.first.position, const NormalizedPoint(1, 0));
    });

    test('rejects malformed input with a FormatException naming the key', () {
      final json = SampleProfiles.minimal.toJson()..['profileName'] = 42;

      expect(
        () => WatchProfile.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('profileName'),
          ),
        ),
      );
    });

    test('rejects a profile from a newer schema', () {
      final json = SampleProfiles.minimal.toJson()..['schemaVersion'] = 999;

      expect(
        () => WatchProfile.fromJson(json),
        throwsA(isA<UnsupportedSchemaVersionException>()),
      );
    });

    test('rejects a missing schemaVersion', () {
      final json = SampleProfiles.minimal.toJson()..remove('schemaVersion');

      expect(() => WatchProfile.fromJson(json), throwsFormatException);
    });

    test('settings equality ignores key order', () {
      final a = SampleProfiles.prdExample.widgets.single;
      final b = a.copyWith(settings: {'showDate': true, 'format': '24h'});

      expect(b, a);
      expect(b.hashCode, a.hashCode);
    });

    test('widgetsInPaintOrder sorts by zIndex and is stable', () {
      const w = WidgetInstance(
        widgetId: 'a',
        type: 'battery',
        position: NormalizedPoint.center,
        size: NormalizedSize(0.1, 0.1),
      );
      final profile = SampleProfiles.minimal.copyWith(widgets: [
        w.copyWith(widgetId: 'top', zIndex: 5),
        w.copyWith(widgetId: 'first0', zIndex: 0),
        w.copyWith(widgetId: 'second0', zIndex: 0),
      ]);

      expect(
        profile.widgetsInPaintOrder.map((w) => w.widgetId),
        ['first0', 'second0', 'top'],
      );
    });

    test('toJson output is plain JSON-encodable', () {
      expect(
          () => jsonEncode(SampleProfiles.minimal.toJson()), returnsNormally);
    });
  });
}
