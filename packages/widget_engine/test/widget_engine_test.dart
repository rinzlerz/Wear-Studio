import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wear_studio_core/wear_studio_core.dart';
import 'package:wear_studio_theme_engine/wear_studio_theme_engine.dart';
import 'package:wear_studio_widget_engine/wear_studio_widget_engine.dart';

const _widget = WidgetInstance(
  widgetId: 'w',
  type: BuiltInWidgetTypes.battery,
  position: NormalizedPoint(0.5, 0.5),
  size: NormalizedSize(0.2, 0.2),
);

WatchProfile _profileWith(List<WidgetInstance> widgets,
        {String theme = 'default_minimalist'}) =>
    WatchProfile(
        profileId: 'p', profileName: 'P', themeId: theme, widgets: widgets);

/// Colour of the time line of the widget keyed `clock_001`.
Color _clockTimeColor(WidgetTester tester) {
  final text = tester.widget<Text>(find
      .descendant(
        of: find.byKey(const ValueKey('clock_001')),
        matching: find.byType(Text),
      )
      .first);
  return text.textSpan!.style!.color!;
}

void main() {
  final registry = WidgetRegistry.builtIn();
  final themes = ThemeRegistry.builtIn();

  group('WidgetRegistry', () {
    test('has the three Phase 2 widgets', () {
      expect(registry.types, {
        BuiltInWidgetTypes.digitalClock,
        BuiltInWidgetTypes.battery,
        BuiltInWidgetTypes.systemStatus,
      });
    });

    test('rejects duplicate registration', () {
      expect(
        () => registry.register(const BatteryDefinition()),
        throwsA(isA<DuplicateWidgetTypeException>()),
      );
    });

    test('every sample profile only uses registered widgets', () {
      for (final profile in SampleProfiles.all) {
        for (final w in profile.widgets) {
          expect(registry.definitionFor(w.type), isNotNull, reason: w.type);
        }
      }
    });

    test('defaults satisfy each definition\'s own limits', () {
      for (final d in registry.definitions) {
        expect(d.sizeLimits.allows(d.defaultSize), isTrue, reason: d.type);
        for (final field in d.settings) {
          expect(field.accepts(field.defaultValue), isTrue, reason: field.key);
        }
      }
    });
  });

  group('resolveSettings', () {
    const clock = DigitalClockDefinition();

    test('fills defaults for missing keys', () {
      expect(clock.resolveSettings({}), {'format': '24h', 'showDate': true});
    });

    test('replaces invalid values and drops unknown keys', () {
      expect(
        clock.resolveSettings({'format': '13h', 'showDate': 'yes', 'extra': 1}),
        {'format': '24h', 'showDate': true},
      );
    });

    test('keeps valid values', () {
      expect(
        clock.resolveSettings({'format': '12h', 'showDate': false}),
        {'format': '12h', 'showDate': false},
      );
    });
  });

  group('resolveLayout', () {
    test('converts normalized centre/size to pixels', () {
      final items = resolveLayout(_profileWith([_widget]), registry, 200);

      expect(items.single.rect, const Rect.fromLTWH(80, 80, 40, 40));
    });

    test('clamps sizes to the definition limits', () {
      final tiny = _widget.copyWith(size: const NormalizedSize(0.01, 0.01));

      final item = resolveLayout(_profileWith([tiny]), registry, 100).single;

      expect(item.rect.width, closeTo(12, 1e-9)); // battery minWidth 0.12
      expect(item.rect.height, closeTo(8, 1e-9)); // minHeight 0.08
    });

    test('skips hidden widgets and orders by zIndex', () {
      final items = resolveLayout(
        _profileWith([
          _widget.copyWith(widgetId: 'top', zIndex: 3),
          _widget.copyWith(widgetId: 'hidden', visible: false),
          _widget.copyWith(widgetId: 'bottom', zIndex: 0),
        ]),
        registry,
        100,
      );

      expect(items.map((i) => i.instance.widgetId), ['bottom', 'top']);
    });

    test('unknown types resolve without a definition', () {
      final item = resolveLayout(
        _profileWith([_widget.copyWith(type: 'weather')]),
        registry,
        100,
      ).single;

      expect(item.definition, isNull);
    });
  });

  group('DigitalClockView formatting', () {
    test('24h and 12h', () {
      final t = DateTime(2026, 11, 21, 21, 5);
      expect(DigitalClockView.formatTime(t, use24h: true), '21:05');
      expect(DigitalClockView.formatTime(t, use24h: false), '9:05');
      expect(
          DigitalClockView.formatTime(DateTime(2026, 1, 1, 0, 7),
              use24h: false),
          '12:07');
      expect(DigitalClockView.formatDate(t), 'Sat 21 Nov');
    });
  });

  group('MinuteClock', () {
    test('start and stop control the timer', () {
      final clock = MinuteClock();
      addTearDown(clock.dispose);

      expect(clock.isRunning, isFalse);
      clock.start();
      expect(clock.isRunning, isTrue);
      clock.stop();
      expect(clock.isRunning, isFalse);
    });
  });

  group('WatchFaceCanvas', () {
    final environment = WatchEnvironment.fixed(
      time: DateTime(2026, 11, 21, 9, 5),
      battery: const BatteryInfo(level: 82, charging: false),
      phoneLink: PhoneLinkState.connected,
    );

    Future<void> pumpCanvas(WidgetTester tester, WatchProfile profile) =>
        tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: WatchEnvironmentScope(
              environment: environment,
              child: Center(
                child: SizedBox.square(
                  dimension: 300,
                  child: WatchFaceCanvas(
                    profile: profile,
                    widgets: registry,
                    themes: themes,
                  ),
                ),
              ),
            ),
          ),
        );

    testWidgets('renders every widget of the profile with live data',
        (tester) async {
      await pumpCanvas(tester, SampleProfiles.minimal);

      for (final w in SampleProfiles.minimal.widgets) {
        expect(find.byKey(ValueKey(w.widgetId)), findsOneWidget);
      }
      expect(find.text('09:05'), findsOneWidget);
      expect(find.text('Sat 21 Nov'), findsOneWidget);
      expect(find.text('82%'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
    });

    testWidgets('positions widgets from normalized coordinates',
        (tester) async {
      await pumpCanvas(tester, _profileWith([_widget]));

      final rect = tester.getRect(find.byKey(const ValueKey('w')));
      final canvas = tester.getRect(find.byType(WatchFaceCanvas));
      expect(rect.center, canvas.center);
      expect(rect.width, closeTo(60, 0.01)); // 0.2 * 300
    });

    testWidgets('shows a placeholder for unknown widget types', (tester) async {
      await pumpCanvas(
          tester, _profileWith([_widget.copyWith(type: 'weather')]));

      expect(find.byType(UnknownWidgetView), findsOneWidget);
      expect(find.text('weather'), findsOneWidget);
    });

    testWidgets('switching theme restyles the same widgets', (tester) async {
      final minimal = SampleProfiles.minimal;
      await pumpCanvas(tester, minimal);
      Color clockColor() => _clockTimeColor(tester);

      expect(clockColor(), BuiltInThemes.minimalist.primary);

      await pumpCanvas(tester, minimal.copyWith(themeId: 'dedsec_green'));

      expect(clockColor(), BuiltInThemes.hacker.primary);
      for (final w in minimal.widgets) {
        expect(find.byKey(ValueKey(w.widgetId)), findsOneWidget);
      }
    });

    testWidgets('theme overrides apply to widgets', (tester) async {
      await pumpCanvas(
        tester,
        SampleProfiles.minimal.copyWith(
          themeOverrides: const ThemeOverrides(primary: '#FF0000'),
        ),
      );

      expect(_clockTimeColor(tester), const Color(0xFFFF0000));
    });

    testWidgets('a low battery uses the accent colour', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: WatchEnvironmentScope(
            environment: WatchEnvironment.fixed(
              battery: const BatteryInfo(level: 10),
            ),
            child: const BatteryView(theme: BuiltInThemes.minimalist),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('10%'));
      expect(text.style!.color, BuiltInThemes.minimalist.accent);
    });
  });
}
