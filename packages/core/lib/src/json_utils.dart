/// Small helpers for reading untrusted JSON with clear error messages.
///
/// Every reader throws a [FormatException] naming the offending key, so a
/// malformed configuration received from another device is rejected instead
/// of crashing the renderer with a TypeError.
library;

String readString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException(_describe(key, 'a string', value));
}

int readInt(Map<String, Object?> json, String key, {int? fallback}) {
  final value = json[key];
  if (value == null && fallback != null) return fallback;
  if (value is int) return value;
  // JSON from some encoders writes whole numbers as 1.0.
  if (value is double && value == value.truncateToDouble() && value.isFinite) {
    return value.toInt();
  }
  throw FormatException(_describe(key, 'an integer', value));
}

double readDouble(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is num) return value.toDouble();
  throw FormatException(_describe(key, 'a number', value));
}

bool readBool(Map<String, Object?> json, String key, {required bool fallback}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is bool) return value;
  throw FormatException(_describe(key, 'a boolean', value));
}

Map<String, Object?> readMap(
  Map<String, Object?> json,
  String key, {
  bool optional = false,
}) {
  final value = json[key];
  if (value == null && optional) return <String, Object?>{};
  return asJsonMap(value, key);
}

List<Object?> readList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is List) return List<Object?>.from(value);
  throw FormatException(_describe(key, 'a list', value));
}

/// Converts any map with string keys into a `Map<String, Object?>`.
Map<String, Object?> asJsonMap(Object? value, String context) {
  if (value is Map) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final k = entry.key;
      if (k is! String) {
        throw FormatException('"$context" contains a non-string key: $k');
      }
      result[k] = entry.value;
    }
    return result;
  }
  throw FormatException(_describe(context, 'an object', value));
}

String _describe(String key, String expected, Object? actual) =>
    'Expected "$key" to be $expected but found '
    '${actual == null ? 'nothing' : actual.runtimeType}';

/// Structural equality for JSON-like values (maps, lists, primitives).
bool jsonDeepEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !jsonDeepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!jsonDeepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// Hash consistent with [jsonDeepEquals] (map entry order does not matter).
int jsonDeepHash(Object? value) {
  if (value is Map) {
    var hash = 0;
    for (final entry in value.entries) {
      // XOR keeps the hash independent of entry order.
      hash ^= Object.hash(entry.key, jsonDeepHash(entry.value));
    }
    return hash;
  }
  if (value is List) return Object.hashAll(value.map(jsonDeepHash));
  return value.hashCode;
}
