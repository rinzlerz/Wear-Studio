import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wear_studio_platform/wear_studio_platform.dart';

import 'data/profile_store.dart';

/// Overridden in tests with fakes.
final dataLayerProvider =
    Provider<DataLayer>((ref) => MethodChannelDataLayer());

final profileStoreProvider =
    Provider<ProfileStore>((ref) => FileProfileStore());

final deviceInfoProvider = FutureProvider<WearDeviceInfo>(
  (ref) => MethodChannelDeviceInfo().load(),
);
