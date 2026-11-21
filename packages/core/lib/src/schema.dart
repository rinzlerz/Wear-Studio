/// Configuration schema versioning (PRD §6.1).
///
/// Every stored or synchronized profile carries `schemaVersion`. When the
/// schema changes, bump [currentSchemaVersion] and add a step to
/// [migrateProfileJson] that upgrades version N to N+1.
library;

/// Version history:
/// * 1: initial format (PRD §6.1).
/// * 2: adds optional `themeOverrides` (Phase 2, theme engine).
const int currentSchemaVersion = 2;

class UnsupportedSchemaVersionException implements Exception {
  const UnsupportedSchemaVersionException(this.version);

  final int version;

  @override
  String toString() =>
      'UnsupportedSchemaVersionException: profile uses schema $version, '
      'this app supports up to $currentSchemaVersion. Update the app.';
}

/// Returns [json] upgraded to [currentSchemaVersion].
Map<String, Object?> migrateProfileJson(Map<String, Object?> json) {
  final version = json['schemaVersion'];
  if (version is! int || version < 1) {
    throw FormatException(
      'Expected "schemaVersion" to be a positive integer but found $version',
    );
  }
  if (version > currentSchemaVersion) {
    throw UnsupportedSchemaVersionException(version);
  }

  var migrated = Map<String, Object?>.of(json);
  if (version < 2) migrated = _v1ToV2(migrated);
  // Add further steps here as the schema evolves.
  migrated['schemaVersion'] = currentSchemaVersion;
  return migrated;
}

Map<String, Object?> _v1ToV2(Map<String, Object?> json) =>
    {...json, 'themeOverrides': json['themeOverrides'] ?? <String, Object?>{}};
