import 'package:test/test.dart';
import 'package:wear_studio_core/wear_studio_core.dart';

void main() {
  test('a v1 profile migrates to the current schema with no overrides', () {
    final v1 = {
      'schemaVersion': 1,
      'profileId': 'old',
      'profileName': 'Old',
      'themeId': 'default_minimalist',
      'widgets': <Object?>[],
    };

    final profile = WatchProfile.fromJson(v1);

    expect(profile.schemaVersion, currentSchemaVersion);
    expect(profile.themeOverrides, ThemeOverrides.none);
    expect(profile.toJson()['schemaVersion'], currentSchemaVersion);
  });

  test('migration does not modify the input map', () {
    final v1 = <String, Object?>{'schemaVersion': 1};

    migrateProfileJson(v1);

    expect(v1, {'schemaVersion': 1});
  });

  test('theme overrides round-trip and omit unset fields', () {
    const overrides =
        ThemeOverrides(primary: '#FF00FF', fontScale: 1.2, glow: false);
    final profile = SampleProfiles.minimal.copyWith(themeOverrides: overrides);

    final decoded = WatchProfile.fromJsonString(profile.toJsonString());

    expect(decoded.themeOverrides, overrides);
    expect(overrides.toJson().keys, ['primary', 'fontScale', 'glow']);
    expect(ThemeOverrides.none.isEmpty, isTrue);
  });

  test('malformed overrides are rejected', () {
    final json = SampleProfiles.minimal.toJson()
      ..['themeOverrides'] = {'glow': 'yes'};

    expect(() => WatchProfile.fromJson(json), throwsFormatException);
  });
}
