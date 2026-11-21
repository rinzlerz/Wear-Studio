import 'model/normalized.dart';
import 'model/theme_overrides.dart';
import 'model/watch_profile.dart';
import 'model/widget_instance.dart';
import 'model/widget_types.dart';

/// Sample profiles used for testing sync and rendering until the editor
/// (Phase 3) can create real ones. They all use the same three widget types
/// with different themes, to show themes are independent of widgets.
abstract final class SampleProfiles {
  static const minimal = WatchProfile(
    profileId: 'minimal',
    profileName: 'Minimal',
    themeId: 'default_minimalist',
    widgets: [
      WidgetInstance(
        widgetId: 'status_001',
        type: BuiltInWidgetTypes.systemStatus,
        position: NormalizedPoint(0.5, 0.2),
        size: NormalizedSize(0.4, 0.09),
        settings: {'showLabel': true},
      ),
      WidgetInstance(
        widgetId: 'clock_001',
        type: BuiltInWidgetTypes.digitalClock,
        position: NormalizedPoint(0.5, 0.45),
        size: NormalizedSize(0.7, 0.28),
        zIndex: 1,
        settings: {'format': '24h', 'showDate': true},
      ),
      WidgetInstance(
        widgetId: 'battery_001',
        type: BuiltInWidgetTypes.battery,
        position: NormalizedPoint(0.5, 0.76),
        size: NormalizedSize(0.22, 0.22),
        settings: {'style': 'ring', 'showPercent': true},
      ),
    ],
  );

  static const cyberpunk = WatchProfile(
    profileId: 'cyberpunk',
    profileName: 'Cyberpunk',
    themeId: 'cyberpunk',
    widgets: [
      WidgetInstance(
        widgetId: 'clock_001',
        type: BuiltInWidgetTypes.digitalClock,
        position: NormalizedPoint(0.5, 0.38),
        size: NormalizedSize(0.74, 0.3),
        zIndex: 1,
        settings: {'format': '24h', 'showDate': true},
      ),
      WidgetInstance(
        widgetId: 'battery_001',
        type: BuiltInWidgetTypes.battery,
        position: NormalizedPoint(0.32, 0.72),
        size: NormalizedSize(0.24, 0.24),
        settings: {'style': 'ring', 'showPercent': true},
      ),
      WidgetInstance(
        widgetId: 'status_001',
        type: BuiltInWidgetTypes.systemStatus,
        position: NormalizedPoint(0.68, 0.72),
        size: NormalizedSize(0.26, 0.12),
        settings: {'showLabel': false},
      ),
    ],
  );

  /// Hacker look; the theme id comes from the PRD example.
  static const hacker = WatchProfile(
    profileId: 'hacker',
    profileName: 'Hacker',
    themeId: 'dedsec_green',
    themeOverrides: ThemeOverrides(glow: true),
    widgets: [
      WidgetInstance(
        widgetId: 'clock_001',
        type: BuiltInWidgetTypes.digitalClock,
        position: NormalizedPoint(0.5, 0.3),
        size: NormalizedSize(0.8, 0.26),
        zIndex: 1,
        settings: {'format': '24h', 'showDate': true},
      ),
      WidgetInstance(
        widgetId: 'status_001',
        type: BuiltInWidgetTypes.systemStatus,
        position: NormalizedPoint(0.5, 0.58),
        size: NormalizedSize(0.5, 0.1),
        settings: {'showLabel': true},
      ),
      WidgetInstance(
        widgetId: 'battery_001',
        type: BuiltInWidgetTypes.battery,
        position: NormalizedPoint(0.5, 0.76),
        size: NormalizedSize(0.4, 0.1),
        settings: {'style': 'text', 'showPercent': true},
      ),
    ],
  );

  static const aiInterface = WatchProfile(
    profileId: 'ai_interface',
    profileName: 'AI Interface',
    themeId: 'jarvis_blue',
    widgets: [
      WidgetInstance(
        widgetId: 'battery_001',
        type: BuiltInWidgetTypes.battery,
        position: NormalizedPoint(0.5, 0.5),
        size: NormalizedSize(0.62, 0.62),
        settings: {'style': 'ring', 'showPercent': false},
      ),
      WidgetInstance(
        widgetId: 'clock_001',
        type: BuiltInWidgetTypes.digitalClock,
        position: NormalizedPoint(0.5, 0.5),
        size: NormalizedSize(0.44, 0.22),
        zIndex: 1,
        settings: {'format': '24h', 'showDate': true},
      ),
      WidgetInstance(
        widgetId: 'status_001',
        type: BuiltInWidgetTypes.systemStatus,
        position: NormalizedPoint(0.5, 0.88),
        size: NormalizedSize(0.3, 0.08),
        settings: {'showLabel': false},
      ),
    ],
  );

  /// The example from PRD §6.1.
  static const prdExample = WatchProfile(
    profileId: 'dedsec_profile',
    profileName: 'DedSec',
    themeId: 'dedsec_green',
    widgets: [
      WidgetInstance(
        widgetId: 'clock_001',
        type: BuiltInWidgetTypes.digitalClock,
        position: NormalizedPoint(0.5, 0.2),
        size: NormalizedSize(0.8, 0.15),
        zIndex: 1,
        settings: {'format': '24h', 'showDate': true},
      ),
    ],
  );

  /// Profiles offered by the companion's test buttons.
  static const all = [minimal, cyberpunk, hacker, aiInterface];
}
