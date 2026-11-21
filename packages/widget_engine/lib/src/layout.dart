import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:wear_studio_core/wear_studio_core.dart';

import 'widget_definition.dart';
import 'widget_registry.dart';

/// A widget placed on a canvas of a given size.
@immutable
class ResolvedWidget {
  const ResolvedWidget({
    required this.instance,
    required this.definition,
    required this.rect,
    required this.settings,
  });

  final WidgetInstance instance;

  /// Null when the type is not registered on this device.
  final WatchWidgetDefinition? definition;

  /// Position and size in logical pixels.
  final Rect rect;
  final Map<String, Object?> settings;
}

/// Converts a profile's normalized layout into pixel rectangles on a square
/// canvas of [side] logical pixels.
///
/// * hidden widgets are skipped
/// * results are in paint order (lowest zIndex first)
/// * sizes are clamped to each definition's [SizeLimits]
/// * settings are resolved against each definition's schema
List<ResolvedWidget> resolveLayout(
  WatchProfile profile,
  WidgetRegistry registry,
  double side,
) =>
    [
      for (final instance in profile.widgetsInPaintOrder)
        if (instance.visible) _resolve(instance, registry, side),
    ];

ResolvedWidget _resolve(
  WidgetInstance instance,
  WidgetRegistry registry,
  double side,
) {
  final definition = registry.definitionFor(instance.type);
  final size = definition?.sizeLimits.clamp(instance.size) ?? instance.size;
  return ResolvedWidget(
    instance: instance,
    definition: definition,
    rect: Rect.fromCenter(
      center: Offset(instance.position.x * side, instance.position.y * side),
      width: size.width * side,
      height: size.height * side,
    ),
    settings:
        definition?.resolveSettings(instance.settings) ?? instance.settings,
  );
}
