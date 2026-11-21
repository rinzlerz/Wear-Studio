import 'dart:convert';

import '../json_utils.dart';
import '../schema.dart';
import 'widget_instance.dart';

/// A complete, synchronizable watch configuration (PRD §6.1, FR-008).
class WatchProfile {
  const WatchProfile({
    this.schemaVersion = currentSchemaVersion,
    required this.profileId,
    required this.profileName,
    required this.themeId,
    this.widgets = const [],
  });

  /// Parses a profile, migrating older schema versions first.
  ///
  /// Throws [FormatException] for malformed input and
  /// [UnsupportedSchemaVersionException] for profiles written by a newer app.
  factory WatchProfile.fromJson(Map<String, Object?> json) {
    final migrated = migrateProfileJson(json);
    return WatchProfile(
      schemaVersion: readInt(migrated, 'schemaVersion'),
      profileId: readString(migrated, 'profileId'),
      profileName: readString(migrated, 'profileName'),
      themeId: readString(migrated, 'themeId'),
      widgets: List.unmodifiable(
        readList(migrated, 'widgets').indexed.map(
              (entry) => WidgetInstance.fromJson(
                asJsonMap(entry.$2, 'widgets[${entry.$1}]'),
              ),
            ),
      ),
    );
  }

  factory WatchProfile.fromJsonString(String source) =>
      WatchProfile.fromJson(asJsonMap(jsonDecode(source), 'profile'));

  final int schemaVersion;
  final String profileId;
  final String profileName;
  final String themeId;
  final List<WidgetInstance> widgets;

  /// Widgets in paint order (lowest zIndex first; stable for ties).
  List<WidgetInstance> get widgetsInPaintOrder {
    final indexed = widgets.indexed.toList()
      ..sort((a, b) {
        final byZ = a.$2.zIndex.compareTo(b.$2.zIndex);
        return byZ != 0 ? byZ : a.$1.compareTo(b.$1);
      });
    return [for (final e in indexed) e.$2];
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'profileId': profileId,
        'profileName': profileName,
        'themeId': themeId,
        'widgets': [for (final w in widgets) w.toJson()],
      };

  String toJsonString() => jsonEncode(toJson());

  WatchProfile copyWith({
    String? profileId,
    String? profileName,
    String? themeId,
    List<WidgetInstance>? widgets,
  }) =>
      WatchProfile(
        schemaVersion: schemaVersion,
        profileId: profileId ?? this.profileId,
        profileName: profileName ?? this.profileName,
        themeId: themeId ?? this.themeId,
        widgets: widgets ?? this.widgets,
      );

  @override
  bool operator ==(Object other) {
    if (other is! WatchProfile ||
        other.schemaVersion != schemaVersion ||
        other.profileId != profileId ||
        other.profileName != profileName ||
        other.themeId != themeId ||
        other.widgets.length != widgets.length) {
      return false;
    }
    for (var i = 0; i < widgets.length; i++) {
      if (other.widgets[i] != widgets[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        profileId,
        profileName,
        themeId,
        Object.hashAll(widgets),
      );

  @override
  String toString() =>
      'WatchProfile($profileId, "$profileName", ${widgets.length} widgets)';
}
