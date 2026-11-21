import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wear_studio_platform/wear_studio_platform.dart';
import 'package:wear_studio_theme_engine/wear_studio_theme_engine.dart';
import 'package:wear_studio_widget_engine/wear_studio_widget_engine.dart';

import 'data/profile_store.dart';

/// Overridden in tests with fakes.
final dataLayerProvider =
    Provider<DataLayer>((ref) => MethodChannelDataLayer());

final profileStoreProvider =
    Provider<ProfileStore>((ref) => FileProfileStore());

final batterySourceProvider =
    Provider<BatterySource>((ref) => MethodChannelBatterySource());

final deviceInfoProvider = FutureProvider<WearDeviceInfo>(
  (ref) => MethodChannelDeviceInfo().load(),
);

/// Widget types this watch can render.
final widgetRegistryProvider =
    Provider<WidgetRegistry>((ref) => WidgetRegistry.builtIn());

/// Themes available on this watch.
final themeRegistryProvider =
    Provider<ThemeRegistry>((ref) => ThemeRegistry.builtIn());
