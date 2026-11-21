import '../model/watch_profile.dart';
import '../model/widget_instance.dart';

enum IssueSeverity { error, warning }

class ValidationIssue {
  const ValidationIssue(this.severity, this.path, this.message);

  final IssueSeverity severity;

  /// Location in the profile, e.g. `widgets[2].size.width`.
  final String path;
  final String message;

  @override
  String toString() => '${severity.name}: $path: $message';
}

class ValidationResult {
  const ValidationResult(this.issues);

  final List<ValidationIssue> issues;

  Iterable<ValidationIssue> get errors =>
      issues.where((i) => i.severity == IssueSeverity.error);
  Iterable<ValidationIssue> get warnings =>
      issues.where((i) => i.severity == IssueSeverity.warning);

  /// Warnings do not block a profile from being applied; errors do.
  bool get isValid => errors.isEmpty;

  @override
  String toString() => issues.isEmpty ? 'valid' : issues.join('\n');
}

/// Semantic validation for profiles received from storage or another device
/// (PRD NFR-003, NFR-004). Structural problems are caught earlier by
/// `WatchProfile.fromJson`.
class ProfileValidator {
  const ProfileValidator({this.knownWidgetTypes, this.maxWidgets = 32});

  /// When set, widget types outside this set are errors. Leave null on a
  /// device that should tolerate types it cannot render yet.
  final Set<String>? knownWidgetTypes;

  /// Guards the watch against oversized layouts.
  final int maxWidgets;

  static final _idPattern = RegExp(r'^[A-Za-z0-9_\-]{1,64}$');

  ValidationResult validate(WatchProfile profile) {
    final issues = <ValidationIssue>[];
    void error(String path, String message) =>
        issues.add(ValidationIssue(IssueSeverity.error, path, message));
    void warning(String path, String message) =>
        issues.add(ValidationIssue(IssueSeverity.warning, path, message));

    if (!_idPattern.hasMatch(profile.profileId)) {
      error('profileId', 'must be 1-64 letters, digits, "_" or "-"');
    }
    if (profile.profileName.trim().isEmpty) {
      error('profileName', 'must not be empty');
    }
    if (profile.themeId.trim().isEmpty) {
      error('themeId', 'must not be empty');
    }
    if (profile.widgets.length > maxWidgets) {
      error(
          'widgets', 'has ${profile.widgets.length} widgets; max $maxWidgets');
    }

    final seenIds = <String>{};
    for (final (index, widget) in profile.widgets.indexed) {
      final base = 'widgets[$index]';
      if (!_idPattern.hasMatch(widget.widgetId)) {
        error('$base.widgetId', 'must be 1-64 letters, digits, "_" or "-"');
      } else if (!seenIds.add(widget.widgetId)) {
        error('$base.widgetId', 'duplicate id "${widget.widgetId}"');
      }
      if (widget.type.isEmpty) {
        error('$base.type', 'must not be empty');
      } else if (knownWidgetTypes != null &&
          !knownWidgetTypes!.contains(widget.type)) {
        error('$base.type', 'unknown widget type "${widget.type}"');
      }
      _checkGeometry(widget, base, error, warning);
    }

    return ValidationResult(List.unmodifiable(issues));
  }

  void _checkGeometry(
    WidgetInstance widget,
    String base,
    void Function(String, String) error,
    void Function(String, String) warning,
  ) {
    final p = widget.position;
    final s = widget.size;

    void unit(String path, double v) {
      if (!v.isFinite || v < 0 || v > 1) {
        error(path, 'must be between 0.0 and 1.0 (was $v)');
      }
    }

    unit('$base.position.x', p.x);
    unit('$base.position.y', p.y);
    for (final (name, v) in [('width', s.width), ('height', s.height)]) {
      if (!v.isFinite || v <= 0 || v > 1) {
        error('$base.size.$name', 'must be > 0.0 and <= 1.0 (was $v)');
      }
    }

    const epsilon = 1e-9;
    final left = p.x - s.width / 2;
    final right = p.x + s.width / 2;
    final top = p.y - s.height / 2;
    final bottom = p.y + s.height / 2;
    if (left < -epsilon ||
        top < -epsilon ||
        right > 1 + epsilon ||
        bottom > 1 + epsilon) {
      warning(base, 'extends beyond the screen bounds and will be clipped');
    }
  }
}
