import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:wear_studio_core/wear_studio_core.dart';
import 'package:wear_studio_theme_engine/wear_studio_theme_engine.dart';

/// Allowed size range for a widget, in normalized units (PRD FR-002:
/// "resized within defined constraints").
@immutable
class SizeLimits {
  const SizeLimits({
    this.minWidth = 0.05,
    this.minHeight = 0.05,
    this.maxWidth = 1.0,
    this.maxHeight = 1.0,
  });

  final double minWidth;
  final double minHeight;
  final double maxWidth;
  final double maxHeight;

  NormalizedSize clamp(NormalizedSize size) => NormalizedSize(
        size.width.clamp(minWidth, maxWidth),
        size.height.clamp(minHeight, maxHeight),
      );

  bool allows(NormalizedSize size) => clamp(size) == size;
}

/// One configurable option of a widget. The list of fields is the widget's
/// settings schema: used to fill defaults and reject bad values now, and to
/// build the property editor in Phase 3.
sealed class SettingField {
  const SettingField(this.key, this.label);

  final String key;
  final String label;

  Object get defaultValue;

  bool accepts(Object? value);
}

final class ChoiceSetting extends SettingField {
  const ChoiceSetting(
    super.key,
    super.label, {
    required this.options,
    required this.defaultValue,
  });

  final List<String> options;

  @override
  final String defaultValue;

  @override
  bool accepts(Object? value) => value is String && options.contains(value);
}

final class BoolSetting extends SettingField {
  const BoolSetting(super.key, super.label, {required this.defaultValue});

  @override
  final bool defaultValue;

  @override
  bool accepts(Object? value) => value is bool;
}

/// What a widget receives when it is built.
@immutable
class WatchWidgetContext {
  const WatchWidgetContext({
    required this.instance,
    required this.settings,
    required this.size,
    required this.theme,
  });

  final WidgetInstance instance;

  /// Settings with defaults filled in and invalid values replaced.
  final Map<String, Object?> settings;

  /// Size in logical pixels after layout.
  final Size size;
  final WatchTheme theme;
}

/// The common contract every widget type implements (PRD FR-003).
///
/// * identification: [type], [displayName]
/// * rendering: [build]
/// * configuration: [settings], [resolveSettings], [sizeLimits]
/// * data sources: read from `WatchEnvironmentScope.of(context)` in [build]
/// * state and lifecycle: [build] may return a StatefulWidget; listenable
///   data sources stop updating when the host pauses them
///
/// A new widget type is a new subclass registered in a `WidgetRegistry`;
/// the rendering engine does not change.
abstract class WatchWidgetDefinition {
  const WatchWidgetDefinition();

  /// Registry key stored in profiles, e.g. `digital_clock`.
  String get type;

  String get displayName;

  /// Size used when the editor adds this widget.
  NormalizedSize get defaultSize;

  SizeLimits get sizeLimits => const SizeLimits();

  List<SettingField> get settings => const [];

  /// Whether the theme's widget frame (fill, border) is drawn behind it.
  bool get usesFrame => true;

  /// Fills defaults, replaces invalid values and drops unknown keys.
  Map<String, Object?> resolveSettings(Map<String, Object?> raw) =>
      Map.unmodifiable({
        for (final field in settings)
          field.key: field.accepts(raw[field.key])
              ? raw[field.key]
              : field.defaultValue,
      });

  Widget build(BuildContext context, WatchWidgetContext widget);
}
