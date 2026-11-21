import '../json_utils.dart';

/// A point in normalized watch-screen space.
///
/// (0, 0) is the top-left of the watch's bounding square and (1, 1) the
/// bottom-right, so layouts are independent of device pixels (PRD FR-002).
/// For widgets, the point is the widget's **centre**.
class NormalizedPoint {
  const NormalizedPoint(this.x, this.y);

  factory NormalizedPoint.fromJson(Map<String, Object?> json) =>
      NormalizedPoint(readDouble(json, 'x'), readDouble(json, 'y'));

  static const center = NormalizedPoint(0.5, 0.5);

  final double x;
  final double y;

  Map<String, Object?> toJson() => {'x': x, 'y': y};

  NormalizedPoint copyWith({double? x, double? y}) =>
      NormalizedPoint(x ?? this.x, y ?? this.y);

  @override
  bool operator ==(Object other) =>
      other is NormalizedPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'NormalizedPoint($x, $y)';
}

/// A size in normalized watch-screen space (fractions of the screen side).
class NormalizedSize {
  const NormalizedSize(this.width, this.height);

  factory NormalizedSize.fromJson(Map<String, Object?> json) =>
      NormalizedSize(readDouble(json, 'width'), readDouble(json, 'height'));

  final double width;
  final double height;

  Map<String, Object?> toJson() => {'width': width, 'height': height};

  NormalizedSize copyWith({double? width, double? height}) =>
      NormalizedSize(width ?? this.width, height ?? this.height);

  @override
  bool operator ==(Object other) =>
      other is NormalizedSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'NormalizedSize($width x $height)';
}
