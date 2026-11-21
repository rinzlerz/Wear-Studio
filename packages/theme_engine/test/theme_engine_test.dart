import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wear_studio_core/wear_studio_core.dart';
import 'package:wear_studio_theme_engine/wear_studio_theme_engine.dart';

void main() {
  group('parseHexColor', () {
    test('reads 6 and 8 digit colours', () {
      expect(parseHexColor('#FF0000'), const Color(0xFFFF0000));
      expect(parseHexColor('#80FF0000'), const Color(0x80FF0000));
    });

    test('rejects anything else', () {
      for (final bad in [null, '', 'red', '#FFF', 'FF0000', '#GG0000']) {
        expect(parseHexColor(bad), isNull, reason: '$bad');
      }
    });
  });

  group('ThemeRegistry', () {
    final registry = ThemeRegistry.builtIn();

    test('contains the four PRD themes', () {
      expect(
        registry.themes.map((t) => t.id),
        containsAll(
            ['default_minimalist', 'cyberpunk', 'dedsec_green', 'jarvis_blue']),
      );
    });

    test('every sample profile resolves to a real theme', () {
      for (final profile in SampleProfiles.all) {
        expect(registry.lookup(profile.themeId), isNotNull,
            reason: profile.profileId);
      }
    });

    test('unknown ids fall back to Minimalist', () {
      expect(registry.resolve('does_not_exist').id, 'default_minimalist');
    });

    test('duplicate registration is rejected', () {
      expect(
        () => registry.register(BuiltInThemes.cyberpunk),
        throwsA(isA<DuplicateThemeException>()),
      );
    });
  });

  group('overrides', () {
    test('replace only the fields that are set', () {
      final theme = BuiltInThemes.cyberpunk.applyOverrides(
        const ThemeOverrides(primary: '#112233', fontScale: 1.2, glow: false),
      );

      expect(theme.primary, const Color(0xFF112233));
      expect(theme.fontScale, 1.2);
      expect(theme.glow, isFalse);
      expect(theme.secondary, BuiltInThemes.cyberpunk.secondary);
      expect(
          theme.backgroundGradient, BuiltInThemes.cyberpunk.backgroundGradient);
    });

    test('a custom background removes the gradient', () {
      final theme = BuiltInThemes.cyberpunk.applyOverrides(
        const ThemeOverrides(background: '#000000'),
      );

      expect(theme.background, const Color(0xFF000000));
      expect(theme.backgroundGradient, isNull);
    });

    test('invalid values are ignored or clamped', () {
      final theme = BuiltInThemes.minimalist.applyOverrides(
        const ThemeOverrides(primary: 'nope', fontScale: 9),
      );

      expect(theme.primary, BuiltInThemes.minimalist.primary);
      expect(theme.fontScale, ThemeOverrides.maxFontScale);
    });

    test('no overrides returns the same theme', () {
      expect(
        identical(BuiltInThemes.hacker.applyOverrides(ThemeOverrides.none),
            BuiltInThemes.hacker),
        isTrue,
      );
    });
  });

  testWidgets('WatchThemeScope provides the theme and defaults to Minimalist',
      (tester) async {
    late WatchTheme seen;
    Widget probe() => Builder(builder: (context) {
          seen = WatchThemeScope.of(context);
          return const SizedBox();
        });

    await tester.pumpWidget(probe());
    expect(seen, BuiltInThemes.minimalist);

    await tester.pumpWidget(
      WatchThemeScope(theme: BuiltInThemes.hacker, child: probe()),
    );
    expect(seen, BuiltInThemes.hacker);
  });
}
