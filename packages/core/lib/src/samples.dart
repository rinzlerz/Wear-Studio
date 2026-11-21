import 'model/normalized.dart';
import 'model/watch_profile.dart';
import 'model/widget_instance.dart';
import 'model/widget_types.dart';

/// Sample profiles used by the Phase 1 sync test and by unit tests.
abstract final class SampleProfiles {
  static const minimal = WatchProfile(
    profileId: 'minimal',
    profileName: 'Minimal',
    themeId: 'default_minimalist',
    widgets: [
      WidgetInstance(
        widgetId: 'clock_001',
        type: BuiltInWidgetTypes.digitalClock,
        position: NormalizedPoint(0.5, 0.4),
        size: NormalizedSize(0.7, 0.2),
        zIndex: 1,
        settings: {'format': '24h', 'showDate': true},
      ),
      WidgetInstance(
        widgetId: 'battery_001',
        type: BuiltInWidgetTypes.battery,
        position: NormalizedPoint(0.5, 0.75),
        size: NormalizedSize(0.3, 0.12),
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
}
