import 'dart:ui';

/// Parses `#RRGGBB` or `#AARRGGBB`. Returns null for anything else, so a bad
/// override falls back to the theme's colour instead of crashing.
Color? parseHexColor(String? value) {
  if (value == null) return null;
  final match = RegExp(r'^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$').firstMatch(value);
  if (match == null) return null;
  final hex = match.group(1)!;
  final argb = int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
  return Color(argb);
}
