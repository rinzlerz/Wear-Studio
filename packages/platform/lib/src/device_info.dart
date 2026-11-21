import 'package:flutter/services.dart';

import 'channels.dart';

/// Facts about the device that matter for the Phase 1 feasibility checks.
class WearDeviceInfo {
  const WearDeviceInfo({
    required this.isWatch,
    required this.isScreenRound,
    required this.manufacturer,
    required this.model,
    required this.sdkInt,
  });

  factory WearDeviceInfo.fromMap(Map<Object?, Object?> map) => WearDeviceInfo(
        isWatch: (map['isWatch'] as bool?) ?? false,
        isScreenRound: (map['isScreenRound'] as bool?) ?? false,
        manufacturer: (map['manufacturer'] as String?) ?? 'unknown',
        model: (map['model'] as String?) ?? 'unknown',
        sdkInt: (map['sdkInt'] as int?) ?? 0,
      );

  /// Used when the native side is not available (tests, non-Android).
  static const unknown = WearDeviceInfo(
    isWatch: false,
    isScreenRound: false,
    manufacturer: 'unknown',
    model: 'unknown',
    sdkInt: 0,
  );

  /// `PackageManager.FEATURE_WATCH`.
  final bool isWatch;

  /// `Configuration.isScreenRound()`.
  final bool isScreenRound;
  final String manufacturer;
  final String model;

  /// `Build.VERSION.SDK_INT` (Wear OS 3 = API 30, Wear OS 4 = 33, ...).
  final int sdkInt;

  @override
  String toString() =>
      '$manufacturer $model (API $sdkInt, watch: $isWatch, round: $isScreenRound)';
}

abstract interface class DeviceInfoSource {
  Future<WearDeviceInfo> load();
}

class MethodChannelDeviceInfo implements DeviceInfoSource {
  MethodChannelDeviceInfo({MethodChannel? method})
      : _method = method ?? WearStudioChannels.method;

  final MethodChannel _method;

  @override
  Future<WearDeviceInfo> load() async {
    try {
      final map =
          await _method.invokeMapMethod<Object?, Object?>('getDeviceInfo');
      return map == null ? WearDeviceInfo.unknown : WearDeviceInfo.fromMap(map);
    } on MissingPluginException {
      return WearDeviceInfo.unknown;
    } on PlatformException {
      return WearDeviceInfo.unknown;
    }
  }
}
