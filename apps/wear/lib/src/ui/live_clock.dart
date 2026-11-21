import 'dart:async';

import 'package:flutter/material.dart';

/// Time and date that tick once a minute, aligned to the minute boundary.
///
/// The timer stops while the app is not visible (PRD NFR-002). Ticking per
/// minute rather than per second keeps wake-ups and rebuilds to a minimum.
class LiveClock extends StatefulWidget {
  const LiveClock({super.key, this.use24h = true, this.showDate = true});

  final bool use24h;
  final bool showDate;

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _now = DateTime.now());
      _schedule();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    final untilNextMinute = Duration(
      seconds: 60 - now.second,
      milliseconds: -now.millisecond,
    );
    _timer = Timer(untilNextMinute, () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _schedule();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    String two(int v) => v.toString().padLeft(2, '0');
    final hour = widget.use24h ? _now.hour : ((_now.hour + 11) % 12) + 1;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          child: Text(
            '${widget.use24h ? two(hour) : hour}:${two(_now.minute)}',
            style: text.displayMedium?.copyWith(
              fontWeight: FontWeight.w300,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (widget.showDate)
          Text(
            '${days[_now.weekday - 1]} ${_now.day} ${months[_now.month - 1]}',
            style: text.labelLarge,
          ),
      ],
    );
  }
}
