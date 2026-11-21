import 'dart:math' as math;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:wear_studio_core/wear_studio_core.dart';
import 'package:wear_studio_theme_engine/wear_studio_theme_engine.dart';

import '../environment.dart';
import '../widget_definition.dart';

class BatteryDefinition extends WatchWidgetDefinition {
  const BatteryDefinition();

  /// At or below this level the widget uses the theme's accent colour.
  static const lowLevel = 15;

  @override
  String get type => BuiltInWidgetTypes.battery;

  @override
  String get displayName => 'Battery';

  @override
  NormalizedSize get defaultSize => const NormalizedSize(0.22, 0.22);

  @override
  SizeLimits get sizeLimits =>
      const SizeLimits(minWidth: 0.12, minHeight: 0.08);

  @override
  bool get usesFrame => false;

  @override
  List<SettingField> get settings => const [
        ChoiceSetting('style', 'Style',
            options: ['ring', 'text'], defaultValue: 'ring'),
        BoolSetting('showPercent', 'Show percentage', defaultValue: true),
      ];

  @override
  Widget build(BuildContext context, WatchWidgetContext widget) => BatteryView(
        theme: widget.theme,
        ring: widget.settings['style'] == 'ring',
        showPercent: widget.settings['showPercent'] == true,
      );
}

class BatteryView extends StatelessWidget {
  const BatteryView({
    super.key,
    required this.theme,
    this.ring = true,
    this.showPercent = true,
  });

  final WatchTheme theme;
  final bool ring;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final battery = WatchEnvironmentScope.of(context).battery;
    return ValueListenableBuilder<BatteryInfo>(
      valueListenable: battery,
      builder: (context, info, _) {
        final level = info.level;
        final low = level != null && level <= BatteryDefinition.lowLevel;
        final color = low ? theme.accent : theme.primary;
        final label = level == null ? '--' : '$level%';
        final charging = info.charging == true;

        if (!ring) {
          return FittedBox(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  charging ? Icons.battery_charging_full : Icons.battery_std,
                  color: color,
                  size: 16 * theme.fontScale,
                ),
                if (showPercent) ...[
                  const SizedBox(width: 3),
                  Text(label,
                      style: theme.text(14, color: color, tabular: true)),
                ],
              ],
            ),
          );
        }

        return AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: BatteryRingPainter(
              fraction: (level ?? 0) / 100,
              color: color,
              trackColor: theme.secondary.withValues(alpha: 0.25),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: FittedBox(
                  child: showPercent
                      ? Text(label,
                          style: theme.text(14, color: color, tabular: true))
                      : Icon(
                          charging ? Icons.bolt : Icons.battery_std,
                          color: color,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BatteryRingPainter extends CustomPainter {
  const BatteryRingPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  final double fraction;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.09;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    final sweep = math.pi * 2 * fraction.clamp(0.0, 1.0);
    if (sweep > 0) canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(BatteryRingPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
