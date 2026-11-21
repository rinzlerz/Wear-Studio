import '../json_utils.dart';

/// User customizations applied on top of a built-in theme (PRD FR-004).
///
/// Every field is optional: null means "use the theme's value". Colours are
/// `#RRGGBB` or `#AARRGGBB` strings so this stays pure Dart and JSON-friendly.
class ThemeOverrides {
  const ThemeOverrides({
    this.primary,
    this.secondary,
    this.accent,
    this.background,
    this.fontScale,
    this.glow,
    this.animationIntensity,
  });

  factory ThemeOverrides.fromJson(Map<String, Object?> json) => ThemeOverrides(
        primary: readOptionalString(json, 'primary'),
        secondary: readOptionalString(json, 'secondary'),
        accent: readOptionalString(json, 'accent'),
        background: readOptionalString(json, 'background'),
        fontScale: readOptionalDouble(json, 'fontScale'),
        glow: readOptionalBool(json, 'glow'),
        animationIntensity: readOptionalDouble(json, 'animationIntensity'),
      );

  static const none = ThemeOverrides();

  static final hexColorPattern = RegExp(r'^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$');

  static const minFontScale = 0.7;
  static const maxFontScale = 1.5;

  final String? primary;
  final String? secondary;
  final String? accent;
  final String? background;

  /// Multiplies all text sizes ([minFontScale]..[maxFontScale]).
  final double? fontScale;

  /// Turns the theme's glow effect on or off.
  final bool? glow;

  /// 0.0 (no animation) to 1.0 (full); used by the animation engine (Phase 4).
  final double? animationIntensity;

  bool get isEmpty =>
      primary == null &&
      secondary == null &&
      accent == null &&
      background == null &&
      fontScale == null &&
      glow == null &&
      animationIntensity == null;

  /// Colour fields by name, for validation and display.
  Map<String, String?> get colors => {
        'primary': primary,
        'secondary': secondary,
        'accent': accent,
        'background': background,
      };

  Map<String, Object?> toJson() => {
        if (primary != null) 'primary': primary,
        if (secondary != null) 'secondary': secondary,
        if (accent != null) 'accent': accent,
        if (background != null) 'background': background,
        if (fontScale != null) 'fontScale': fontScale,
        if (glow != null) 'glow': glow,
        if (animationIntensity != null)
          'animationIntensity': animationIntensity,
      };

  @override
  bool operator ==(Object other) =>
      other is ThemeOverrides &&
      other.primary == primary &&
      other.secondary == secondary &&
      other.accent == accent &&
      other.background == background &&
      other.fontScale == fontScale &&
      other.glow == glow &&
      other.animationIntensity == animationIntensity;

  @override
  int get hashCode => Object.hash(
        primary,
        secondary,
        accent,
        background,
        fontScale,
        glow,
        animationIntensity,
      );

  @override
  String toString() => 'ThemeOverrides(${toJson()})';
}
