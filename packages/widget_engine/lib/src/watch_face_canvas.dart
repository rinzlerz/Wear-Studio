import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:wear_studio_core/wear_studio_core.dart';
import 'package:wear_studio_theme_engine/wear_studio_theme_engine.dart';

import 'layout.dart';
import 'widget_definition.dart';
import 'widget_frame.dart';
import 'widget_registry.dart';
import 'widgets/unknown_widget.dart';

/// Renders a [WatchProfile]: background, then every visible widget at its
/// normalized position, in z-order, styled by the profile's theme.
///
/// The canvas is the largest square that fits; on round screens it is
/// clipped to a circle. Data (time, battery, ...) comes from the nearest
/// `WatchEnvironmentScope`.
class WatchFaceCanvas extends StatelessWidget {
  const WatchFaceCanvas({
    super.key,
    required this.profile,
    required this.widgets,
    required this.themes,
    this.round = true,
  });

  final WatchProfile profile;
  final WidgetRegistry widgets;
  final ThemeRegistry themes;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final theme = themes.forProfile(profile);
    return WatchThemeScope(
      theme: theme,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math.min(constraints.maxWidth, constraints.maxHeight);
          if (!side.isFinite || side <= 0) return const SizedBox.shrink();

          final resolved = resolveLayout(profile, widgets, side);
          Widget face = SizedBox.square(
            dimension: side,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.background,
                gradient: theme.backgroundGradient == null
                    ? null
                    : RadialGradient(colors: theme.backgroundGradient!),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (final item in resolved)
                    Positioned.fromRect(
                      // Stable keys: editing one widget never rebuilds or
                      // resets the state of the others.
                      key: ValueKey(item.instance.widgetId),
                      rect: item.rect,
                      child: RepaintBoundary(child: _buildItem(item, theme)),
                    ),
                ],
              ),
            ),
          );
          if (round) face = ClipOval(child: face);
          return Center(child: face);
        },
      ),
    );
  }

  Widget _buildItem(ResolvedWidget item, WatchTheme theme) {
    final definition = item.definition;
    if (definition == null) {
      return WidgetFrame(
        theme: theme,
        child: UnknownWidgetView(type: item.instance.type),
      );
    }
    return WidgetFrame(
      theme: theme,
      enabled: definition.usesFrame,
      child: Builder(
        builder: (context) => definition.build(
          context,
          WatchWidgetContext(
            instance: item.instance,
            settings: item.settings,
            size: item.rect.size,
            theme: theme,
          ),
        ),
      ),
    );
  }
}
