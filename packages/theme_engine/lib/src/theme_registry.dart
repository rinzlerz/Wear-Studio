import 'package:wear_studio_core/wear_studio_core.dart';

import 'built_in_themes.dart';
import 'watch_theme.dart';

class DuplicateThemeException implements Exception {
  const DuplicateThemeException(this.id);

  final String id;

  @override
  String toString() =>
      'DuplicateThemeException: theme "$id" is already registered';
}

/// Lookup of themes by id, with a guaranteed fallback.
class ThemeRegistry {
  ThemeRegistry({required this.fallback}) {
    register(fallback);
  }

  /// The four built-in themes; falls back to Minimalist.
  factory ThemeRegistry.builtIn() {
    final registry = ThemeRegistry(fallback: BuiltInThemes.minimalist);
    for (final theme in BuiltInThemes.all) {
      if (theme.id != registry.fallback.id) registry.register(theme);
    }
    return registry;
  }

  /// Used when a profile names a theme this device does not have.
  final WatchTheme fallback;
  final _themes = <String, WatchTheme>{};

  Iterable<WatchTheme> get themes => _themes.values;

  void register(WatchTheme theme) {
    if (_themes.containsKey(theme.id)) throw DuplicateThemeException(theme.id);
    _themes[theme.id] = theme;
  }

  WatchTheme? lookup(String id) => _themes[id];

  /// The theme for [id] with [overrides] applied, or the fallback.
  WatchTheme resolve(String id,
          [ThemeOverrides overrides = ThemeOverrides.none]) =>
      (_themes[id] ?? fallback).applyOverrides(overrides);

  /// Convenience for a profile.
  WatchTheme forProfile(WatchProfile profile) =>
      resolve(profile.themeId, profile.themeOverrides);
}
