import 'package:flutter/widgets.dart';
import 'package:wear_studio_core/wear_studio_core.dart';
import 'package:wear_studio_theme_engine/wear_studio_theme_engine.dart';

import '../environment.dart';
import '../widget_definition.dart';

class DigitalClockDefinition extends WatchWidgetDefinition {
  const DigitalClockDefinition();

  @override
  String get type => BuiltInWidgetTypes.digitalClock;

  @override
  String get displayName => 'Digital clock';

  @override
  NormalizedSize get defaultSize => const NormalizedSize(0.7, 0.28);

  @override
  SizeLimits get sizeLimits => const SizeLimits(minWidth: 0.3, minHeight: 0.12);

  @override
  bool get usesFrame => false;

  @override
  List<SettingField> get settings => const [
        ChoiceSetting('format', 'Time format',
            options: ['24h', '12h'], defaultValue: '24h'),
        BoolSetting('showDate', 'Show date', defaultValue: true),
      ];

  @override
  Widget build(BuildContext context, WatchWidgetContext widget) =>
      DigitalClockView(
        theme: widget.theme,
        use24h: widget.settings['format'] == '24h',
        showDate: widget.settings['showDate'] == true,
      );
}

class DigitalClockView extends StatelessWidget {
  const DigitalClockView({
    super.key,
    required this.theme,
    this.use24h = true,
    this.showDate = true,
  });

  final WatchTheme theme;
  final bool use24h;
  final bool showDate;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
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

  /// `09:05` (24h) or `9:05` (12h; AM/PM is shown separately).
  static String formatTime(DateTime t, {required bool use24h}) {
    String two(int v) => v.toString().padLeft(2, '0');
    if (use24h) return '${two(t.hour)}:${two(t.minute)}';
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$hour:${two(t.minute)}';
  }

  /// `Sat 21 Nov`.
  static String formatDate(DateTime t) =>
      '${_days[t.weekday - 1]} ${t.day} ${_months[t.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final clock = WatchEnvironmentScope.of(context).clock;
    return ValueListenableBuilder<DateTime>(
      valueListenable: clock,
      builder: (context, now, _) => FittedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                text: formatTime(now, use24h: use24h),
                style: theme.text(
                  40,
                  color: theme.primary,
                  weight: FontWeight.w300,
                  tabular: true,
                ),
                children: [
                  if (!use24h)
                    TextSpan(
                      text: now.hour < 12 ? ' AM' : ' PM',
                      style: theme.text(14, color: theme.secondary),
                    ),
                ],
              ),
            ),
            if (showDate)
              Text(
                formatDate(now),
                style: theme.text(12, color: theme.secondary),
              ),
          ],
        ),
      ),
    );
  }
}
