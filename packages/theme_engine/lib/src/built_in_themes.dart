import 'dart:ui';

import 'watch_theme.dart';

/// The initial themes from PRD FR-004.
///
/// Ids match the PRD and the sample profiles. Display names avoid
/// third-party trademarks ("Watch Dogs"/DedSec, Marvel/JARVIS).
abstract final class BuiltInThemes {
  static const minimalist = WatchTheme(
    id: 'default_minimalist',
    name: 'Minimalist',
    background: Color(0xFF000000),
    primary: Color(0xFFFFFFFF),
    secondary: Color(0xFF9E9E9E),
    accent: Color(0xFF00BFA5),
    onBackground: Color(0xFFFFFFFF),
    surface: WidgetSurfaceStyle(),
    animationPreset: AnimationPreset.subtle,
    animationIntensity: 0.3,
  );

  static const cyberpunk = WatchTheme(
    id: 'cyberpunk',
    name: 'Cyberpunk',
    background: Color(0xFF0B0014),
    backgroundGradient: [Color(0xFF2A0845), Color(0xFF0B0014)],
    primary: Color(0xFFFCEE0A),
    secondary: Color(0xFF00F0FF),
    accent: Color(0xFFFF2A6D),
    onBackground: Color(0xFFFCEE0A),
    surface: WidgetSurfaceStyle(
      fill: Color(0x3300F0FF),
      borderColor: Color(0xFFFF2A6D),
      borderWidth: 1.5,
      cornerRadius: 0.08,
    ),
    glow: true,
    animationPreset: AnimationPreset.glitch,
    animationIntensity: 0.6,
  );

  static const hacker = WatchTheme(
    id: 'dedsec_green',
    name: 'Hacker',
    background: Color(0xFF000000),
    backgroundGradient: [Color(0xFF001A0A), Color(0xFF000000)],
    primary: Color(0xFF39FF14),
    secondary: Color(0xFF1FAA59),
    accent: Color(0xFFFFFFFF),
    onBackground: Color(0xFF39FF14),
    fontFamily: 'monospace',
    surface: WidgetSurfaceStyle(
      borderColor: Color(0xFF1FAA59),
      borderWidth: 1,
      cornerRadius: 0,
    ),
    animationPreset: AnimationPreset.glitch,
    animationIntensity: 0.5,
  );

  static const aiInterface = WatchTheme(
    id: 'jarvis_blue',
    name: 'AI Interface',
    background: Color(0xFF000814),
    backgroundGradient: [Color(0xFF00243D), Color(0xFF000814)],
    primary: Color(0xFF4FD1FF),
    secondary: Color(0xFF8FB8CC),
    accent: Color(0xFFFFB300),
    onBackground: Color(0xFFE0F7FF),
    surface: WidgetSurfaceStyle(cornerRadius: 0.5),
    glow: true,
    animationPreset: AnimationPreset.hud,
    animationIntensity: 0.7,
  );

  static const all = [minimalist, cyberpunk, hacker, aiInterface];
}
