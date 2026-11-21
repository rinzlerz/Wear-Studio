import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wear_studio_widget_engine/wear_studio_widget_engine.dart';

import '../../providers.dart';
import 'watch_controller.dart';

/// Supplies live data (time, battery, phone link) to the widget engine and
/// pauses every source while the app is not visible (PRD NFR-002).
///
/// * time: [MinuteClock], one wake-up per minute
/// * battery: read once a minute and on resume (no native polling)
/// * phone link: mirrored from [watchControllerProvider]
class WatchEnvironmentHost extends ConsumerStatefulWidget {
  const WatchEnvironmentHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WatchEnvironmentHost> createState() =>
      _WatchEnvironmentHostState();
}

class _WatchEnvironmentHostState extends ConsumerState<WatchEnvironmentHost>
    with WidgetsBindingObserver {
  static const _batteryInterval = Duration(minutes: 1);

  final _clock = MinuteClock();
  final _battery = ValueNotifier<BatteryInfo>(BatteryInfo.unknown);
  final _link = ValueNotifier<PhoneLinkState>(PhoneLinkState.unknown);
  late final WatchEnvironment _environment = WatchEnvironment(
    clock: _clock,
    battery: _battery,
    phoneLink: _link,
  );
  Timer? _batteryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(
      watchControllerProvider.select((s) => s.phoneLink),
      (_, next) => _link.value = next,
      fireImmediately: true,
    );
    _resume();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resume();
      // The phone may have connected or gone away while we were hidden.
      unawaited(ref.read(watchControllerProvider.notifier).findPhone());
    } else {
      _pause();
    }
  }

  void _resume() {
    _clock.start();
    unawaited(_readBattery());
    _batteryTimer?.cancel();
    _batteryTimer = Timer.periodic(_batteryInterval, (_) => _readBattery());
  }

  void _pause() {
    _clock.stop();
    _batteryTimer?.cancel();
    _batteryTimer = null;
  }

  Future<void> _readBattery() async {
    final status = await ref.read(batterySourceProvider).read();
    if (!mounted) return;
    _battery.value =
        BatteryInfo(level: status.level, charging: status.charging);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pause();
    _clock.dispose();
    _battery.dispose();
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      WatchEnvironmentScope(environment: _environment, child: widget.child);
}
