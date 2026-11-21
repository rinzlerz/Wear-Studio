import 'widget_definition.dart';
import 'widgets/battery.dart';
import 'widgets/digital_clock.dart';
import 'widgets/system_status.dart';

class DuplicateWidgetTypeException implements Exception {
  const DuplicateWidgetTypeException(this.type);

  final String type;

  @override
  String toString() =>
      'DuplicateWidgetTypeException: widget type "$type" is already registered';
}

/// Maps widget type keys to their definitions (PRD FR-003 registry-based
/// architecture). Registering the same type twice is an error (NFR-003).
class WidgetRegistry {
  WidgetRegistry([Iterable<WatchWidgetDefinition> definitions = const []]) {
    for (final definition in definitions) {
      register(definition);
    }
  }

  /// The widgets implemented so far.
  factory WidgetRegistry.builtIn() => WidgetRegistry(const [
        DigitalClockDefinition(),
        BatteryDefinition(),
        SystemStatusDefinition(),
      ]);

  final _definitions = <String, WatchWidgetDefinition>{};

  void register(WatchWidgetDefinition definition) {
    if (_definitions.containsKey(definition.type)) {
      throw DuplicateWidgetTypeException(definition.type);
    }
    _definitions[definition.type] = definition;
  }

  /// Null when this device cannot render [type] (shown as a placeholder).
  WatchWidgetDefinition? definitionFor(String type) => _definitions[type];

  Set<String> get types => Set.unmodifiable(_definitions.keys);

  Iterable<WatchWidgetDefinition> get definitions => _definitions.values;
}
