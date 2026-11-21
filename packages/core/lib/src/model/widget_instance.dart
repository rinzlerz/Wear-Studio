import '../json_utils.dart';
import 'normalized.dart';

/// One placed widget inside a [WatchProfile] layout (PRD FR-002 / §6.1).
class WidgetInstance {
  const WidgetInstance({
    required this.widgetId,
    required this.type,
    required this.position,
    required this.size,
    this.zIndex = 0,
    this.visible = true,
    this.settings = const {},
  });

  factory WidgetInstance.fromJson(Map<String, Object?> json) => WidgetInstance(
        widgetId: readString(json, 'widgetId'),
        type: readString(json, 'type'),
        position: NormalizedPoint.fromJson(readMap(json, 'position')),
        size: NormalizedSize.fromJson(readMap(json, 'size')),
        zIndex: readInt(json, 'zIndex', fallback: 0),
        visible: readBool(json, 'visible', fallback: true),
        settings: Map.unmodifiable(readMap(json, 'settings', optional: true)),
      );

  /// Unique within a profile.
  final String widgetId;

  /// Registry key, e.g. `digital_clock` (see [BuiltInWidgetTypes]).
  final String type;

  /// Centre of the widget in normalized coordinates.
  final NormalizedPoint position;
  final NormalizedSize size;

  /// Higher values are drawn on top.
  final int zIndex;
  final bool visible;

  /// Widget-specific configuration; must stay JSON-encodable.
  final Map<String, Object?> settings;

  Map<String, Object?> toJson() => {
        'widgetId': widgetId,
        'type': type,
        'position': position.toJson(),
        'size': size.toJson(),
        'zIndex': zIndex,
        'visible': visible,
        'settings': settings,
      };

  WidgetInstance copyWith({
    String? widgetId,
    String? type,
    NormalizedPoint? position,
    NormalizedSize? size,
    int? zIndex,
    bool? visible,
    Map<String, Object?>? settings,
  }) =>
      WidgetInstance(
        widgetId: widgetId ?? this.widgetId,
        type: type ?? this.type,
        position: position ?? this.position,
        size: size ?? this.size,
        zIndex: zIndex ?? this.zIndex,
        visible: visible ?? this.visible,
        settings: settings ?? this.settings,
      );

  @override
  bool operator ==(Object other) =>
      other is WidgetInstance &&
      other.widgetId == widgetId &&
      other.type == type &&
      other.position == position &&
      other.size == size &&
      other.zIndex == zIndex &&
      other.visible == visible &&
      jsonDeepEquals(other.settings, settings);

  @override
  int get hashCode => Object.hash(
        widgetId,
        type,
        position,
        size,
        zIndex,
        visible,
        jsonDeepHash(settings),
      );

  @override
  String toString() => 'WidgetInstance($widgetId, $type)';
}
