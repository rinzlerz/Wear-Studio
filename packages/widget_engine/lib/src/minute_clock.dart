import 'dart:async';

import 'package:flutter/foundation.dart';

/// A clock that updates on each minute boundary while running.
///
/// The host calls [stop] when the app is not visible and [start] when it
/// returns (PRD NFR-002), so no timer fires in the background.
class MinuteClock extends ValueNotifier<DateTime> {
  MinuteClock({DateTime Function()? now})
      : _now = now ?? DateTime.now,
        super((now ?? DateTime.now)());

  final DateTime Function() _now;
  Timer? _timer;

  bool get isRunning => _timer != null;

  void start() {
    value = _now();
    _schedule();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _schedule() {
    _timer?.cancel();
    final now = _now();
    final untilNextMinute = Duration(
      seconds: 60 - now.second,
      milliseconds: -now.millisecond,
    );
    _timer = Timer(untilNextMinute, () {
      value = _now();
      _schedule();
    });
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
