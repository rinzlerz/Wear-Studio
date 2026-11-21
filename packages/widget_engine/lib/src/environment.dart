import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Connection state between the watch and the phone companion.
enum PhoneLinkState { unknown, connected, disconnected, unavailable }

@immutable
class BatteryInfo {
  const BatteryInfo({this.level, this.charging});

  static const unknown = BatteryInfo();

  /// 0-100, or null when not known.
  final int? level;
  final bool? charging;

  @override
  bool operator ==(Object other) =>
      other is BatteryInfo &&
      other.level == level &&
      other.charging == charging;

  @override
  int get hashCode => Object.hash(level, charging);

  @override
  String toString() => 'BatteryInfo($level%, charging: $charging)';
}

/// Live data sources that widgets read (PRD FR-003 "data source
/// integration").
///
/// The engine never talks to the platform. The host app (watch runtime, or
/// the phone preview in Phase 3) supplies these listenables and decides how
/// often they update, which keeps battery use under the host's control.
class WatchEnvironment {
  const WatchEnvironment({
    required this.clock,
    required this.battery,
    required this.phoneLink,
  });

  /// Fixed values, for previews and tests.
  factory WatchEnvironment.fixed({
    DateTime? time,
    BatteryInfo battery = BatteryInfo.unknown,
    PhoneLinkState phoneLink = PhoneLinkState.unknown,
  }) =>
      WatchEnvironment(
        clock: ValueNotifier(time ?? DateTime(2026, 1, 1, 10, 8)),
        battery: ValueNotifier(battery),
        phoneLink: ValueNotifier(phoneLink),
      );

  /// Current time; the host updates it once a minute.
  final ValueListenable<DateTime> clock;
  final ValueListenable<BatteryInfo> battery;
  final ValueListenable<PhoneLinkState> phoneLink;
}

/// Makes a [WatchEnvironment] available to widgets below it.
class WatchEnvironmentScope extends InheritedWidget {
  const WatchEnvironmentScope({
    super.key,
    required this.environment,
    required super.child,
  });

  final WatchEnvironment environment;

  static final WatchEnvironment _fallback = WatchEnvironment.fixed();

  /// The nearest environment, or fixed placeholder values.
  static WatchEnvironment of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<WatchEnvironmentScope>()
          ?.environment ??
      _fallback;

  @override
  bool updateShouldNotify(WatchEnvironmentScope oldWidget) =>
      !identical(environment, oldWidget.environment);
}
