import 'package:flutter/services.dart';

import 'channels.dart';

class BatteryStatus {
  const BatteryStatus({this.level, this.charging});

  factory BatteryStatus.fromMap(Map<Object?, Object?> map) => BatteryStatus(
        level: map['level'] as int?,
        charging: map['charging'] as bool?,
      );

  static const unknown = BatteryStatus();

  /// 0-100, or null when the device does not report it.
  final int? level;
  final bool? charging;

  @override
  String toString() => 'BatteryStatus($level%, charging: $charging)';
}

abstract interface class BatterySource {
  /// Reads the current level. Never throws; returns [BatteryStatus.unknown]
  /// when unavailable.
  Future<BatteryStatus> read();
}

class MethodChannelBatterySource implements BatterySource {
  MethodChannelBatterySource({MethodChannel? method})
      : _method = method ?? WearStudioChannels.method;

  final MethodChannel _method;

  @override
  Future<BatteryStatus> read() async {
    try {
      final map =
          await _method.invokeMapMethod<Object?, Object?>('getBatteryStatus');
      return map == null ? BatteryStatus.unknown : BatteryStatus.fromMap(map);
    } on MissingPluginException {
      return BatteryStatus.unknown;
    } on PlatformException {
      return BatteryStatus.unknown;
    }
  }
}
