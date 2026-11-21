import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:wear_studio_theme_engine/wear_studio_theme_engine.dart';

/// Draws the theme's widget surface (fill, border, glow) behind a widget.
///
/// This is the only place frame styling lives, so a theme change restyles
/// every widget without touching widget code (PRD FR-004).
class WidgetFrame extends StatelessWidget {
  const WidgetFrame({
    super.key,
    required this.theme,
    required this.child,
    this.enabled = true,
  });

  final WatchTheme theme;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final style = theme.surface;
    final hasBorder = style.borderWidth > 0;
    if (!enabled || (style.fill == null && !hasBorder)) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = math.min(constraints.maxWidth, constraints.maxHeight);
        final borderColor = style.borderColor ?? theme.primary;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: style.fill,
            borderRadius: BorderRadius.circular(shortest * style.cornerRadius),
            border: hasBorder
                ? Border.all(color: borderColor, width: style.borderWidth)
                : null,
            boxShadow: theme.glow
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.45),
                      blurRadius: shortest * 0.12,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(shortest * 0.08),
            child: child,
          ),
        );
      },
    );
  }
}
