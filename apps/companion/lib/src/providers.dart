import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wear_studio_platform/wear_studio_platform.dart';

/// Overridden in tests with a fake.
final dataLayerProvider =
    Provider<DataLayer>((ref) => MethodChannelDataLayer());

final deviceInfoProvider = FutureProvider<WearDeviceInfo>(
  (ref) => MethodChannelDeviceInfo().load(),
);
