import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:wear_studio_core/wear_studio_core.dart';

import 'color_hex.dart';

/// How strongly widgets animate; interpreted by the animation engine
/// (PRD FR-005, Phase 4). Stored now so themes can declare it.
enum AnimationPreset { none, subtle, hud, glitch }

/// Look of the frame drawn behind every widget.
@immutable
class WidgetSurfaceStyle {
  const WidgetSurfaceStyle({
    this.fill,
    this.borderColor,
    this.borderWidth = 0,
    this.cornerRadius = 0.2,
  });

  /// Background behind the widget; null for none.
  final Color? fill;

  /// Border colour; null uses the theme's primary colour.
  final Color? borderColor;

  /// Logical pixels; 0 for no border.
  final double borderWidth;

  /// Fraction of the widget's shorter side (0 = square, 0.5 = pill/circle).
  final double cornerRadius;

  WidgetSurfaceStyle copyWith({
    Color? fill,
    Color? borderColor,
    double? borderWidth,
    double? cornerRadius,
  }) =>
      WidgetSurfaceStyle(
        fill: fill ?? this.fill,
        borderColor: borderColor ?? this.borderColor,
        borderWidth: borderWidth ?? this.borderWidth,
        cornerRadius: cornerRadius ?? this.cornerRadius,
      );

  @override
  bool operator ==(Object other) =>
      other is WidgetSurfaceStyle &&
      other.fill == fill &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.cornerRadius == cornerRadius;

  @override
  int get hashCode => Object.hash(fill, borderColor, borderWidth, cornerRadius);
}

/// Everything a widget needs to style itself (PRD FR-004).
///
/// Widgets read colours and text styles from here and never hard-code them,
/// so switching theme restyles every widget without changing widget code.
@immutable
class WatchTheme {
  const WatchTheme({
    required this.id,
    required this.name,
    required this.background,
    this.backgroundGradient,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.onBackground,
    this.fontFamily,
    this.fontScale = 1.0,
    this.surface = const WidgetSurfaceStyle(),
    this.glow = false,
    this.animationPreset = AnimationPreset.none,
    this.animationIntensity = 0.5,
  });

  final String id;

  /// Shown to users. Kept generic (no third-party brand names).
  final String name;

  /// Solid background, also the outer colour of [backgroundGradient].
  final Color background;

  /// Optional radial gradient from the centre outwards.
  final List<Color>? backgroundGradient;

  /// Main foreground colour (clock digits, rings).
  final Color primary;

  /// Supporting text (dates, labels).
  final Color secondary;

  /// Highlights and warnings.
  final Color accent;

  /// Default text colour on [background].
  final Color onBackground;

  /// Null uses the platform default. Use generic families such as
  /// `monospace`; custom fonts would need bundling.
  final String? fontFamily;

  /// Multiplies every text size.
  final double fontScale;
  final WidgetSurfaceStyle surface;

  /// Adds a soft glow around widget frames and text.
  final bool glow;
  final AnimationPreset animationPreset;
  final double animationIntensity;

  /// Text style in this theme. [size] is a logical size before [fontScale].
  TextStyle text(
    double size, {
    Color? color,
    FontWeight? weight,
    bool tabular = false,
  }) {
    final c = color ?? onBackground;
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size * fontScale,
      color: c,
      fontWeight: weight,
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
      shadows: glow
          ? [Shadow(color: c.withValues(alpha: 0.8), blurRadius: size * 0.35)]
          : null,
    );
  }

  /// Applies a profile's user overrides. Invalid values are ignored.
  WatchTheme applyOverrides(ThemeOverrides overrides) {
    if (overrides.isEmpty) return this;
    final bg = parseHexColor(overrides.background);
    return copyWith(
      primary: parseHexColor(overrides.primary),
      secondary: parseHexColor(overrides.secondary),
      accent: parseHexColor(overrides.accent),
      background: bg,
      // A custom background replaces the gradient so the colour shows.
      clearGradient: bg != null,
      fontScale: overrides.fontScale?.clamp(
        ThemeOverrides.minFontScale,
        ThemeOverrides.maxFontScale,
      ),
      glow: overrides.glow,
      animationIntensity: overrides.animationIntensity?.clamp(0.0, 1.0),
    );
  }

  WatchTheme copyWith({
    String? id,
    String? name,
    Color? background,
    List<Color>? backgroundGradient,
    bool clearGradient = false,
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? onBackground,
    String? fontFamily,
    double? fontScale,
    WidgetSurfaceStyle? surface,
    bool? glow,
    AnimationPreset? animationPreset,
    double? animationIntensity,
  }) =>
      WatchTheme(
        id: id ?? this.id,
        name: name ?? this.name,
        background: background ?? this.background,
        backgroundGradient: clearGradient
            ? null
            : (backgroundGradient ?? this.backgroundGradient),
        primary: primary ?? this.primary,
        secondary: secondary ?? this.secondary,
        accent: accent ?? this.accent,
        onBackground: onBackground ?? this.onBackground,
        fontFamily: fontFamily ?? this.fontFamily,
        fontScale: fontScale ?? this.fontScale,
        surface: surface ?? this.surface,
        glow: glow ?? this.glow,
        animationPreset: animationPreset ?? this.animationPreset,
        animationIntensity: animationIntensity ?? this.animationIntensity,
      );

  @override
  bool operator ==(Object other) =>
      other is WatchTheme &&
      other.id == id &&
      other.name == name &&
      other.background == background &&
      _listEquals(other.backgroundGradient, backgroundGradient) &&
      other.primary == primary &&
      other.secondary == secondary &&
      other.accent == accent &&
      other.onBackground == onBackground &&
      other.fontFamily == fontFamily &&
      other.fontScale == fontScale &&
      other.surface == surface &&
      other.glow == glow &&
      other.animationPreset == animationPreset &&
      other.animationIntensity == animationIntensity;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        background,
        backgroundGradient == null ? null : Object.hashAll(backgroundGradient!),
        primary,
        secondary,
        accent,
        onBackground,
        fontFamily,
        fontScale,
        surface,
        glow,
        animationPreset,
        animationIntensity,
      );

  static bool _listEquals(List<Color>? a, List<Color>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'WatchTheme($id)';
}
