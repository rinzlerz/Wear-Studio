import 'package:test/test.dart';
import 'package:wear_studio_core/wear_studio_core.dart';

void main() {
  const validator = ProfileValidator(knownWidgetTypes: BuiltInWidgetTypes.all);

  const widget = WidgetInstance(
    widgetId: 'w1',
    type: BuiltInWidgetTypes.battery,
    position: NormalizedPoint(0.5, 0.5),
    size: NormalizedSize(0.2, 0.2),
  );

  WatchProfile withWidgets(List<WidgetInstance> widgets) =>
      SampleProfiles.minimal.copyWith(widgets: widgets);

  test('sample profiles are valid with no warnings', () {
    for (final p in [SampleProfiles.minimal, SampleProfiles.prdExample]) {
      final result = validator.validate(p);
      expect(result.issues, isEmpty, reason: result.toString());
    }
  });

  test('duplicate widget ids are errors', () {
    final result = validator.validate(withWidgets([widget, widget]));

    expect(result.isValid, isFalse);
    expect(result.errors.single.path, 'widgets[1].widgetId');
  });

  test('coordinates outside 0..1 are errors', () {
    final result = validator.validate(withWidgets([
      widget.copyWith(position: const NormalizedPoint(1.2, -0.1)),
    ]));

    expect(
      result.errors.map((e) => e.path),
      containsAll(['widgets[0].position.x', 'widgets[0].position.y']),
    );
  });

  test('zero, negative and NaN sizes are errors', () {
    final result = validator.validate(withWidgets([
      widget.copyWith(size: const NormalizedSize(0, double.nan)),
    ]));

    expect(
      result.errors.map((e) => e.path),
      containsAll(['widgets[0].size.width', 'widgets[0].size.height']),
    );
  });

  test('a widget overflowing the screen is only a warning', () {
    final result = validator.validate(withWidgets([
      widget.copyWith(
        position: const NormalizedPoint(0.95, 0.5),
        size: const NormalizedSize(0.3, 0.2),
      ),
    ]));

    expect(result.isValid, isTrue);
    expect(result.warnings, hasLength(1));
  });

  test('unknown widget types are errors only when a registry is given', () {
    final profile = withWidgets([widget.copyWith(type: 'teleporter')]);

    expect(validator.validate(profile).isValid, isFalse);
    expect(const ProfileValidator().validate(profile).isValid, isTrue);
  });

  test('bad profile ids and empty names are errors', () {
    final result = validator.validate(
      SampleProfiles.minimal.copyWith(profileId: 'has space', profileName: ' '),
    );

    expect(
      result.errors.map((e) => e.path),
      containsAll(['profileId', 'profileName']),
    );
  });

  test('too many widgets is an error', () {
    final many = [
      for (var i = 0; i < 5; i++) widget.copyWith(widgetId: 'w$i'),
    ];

    final result = const ProfileValidator(maxWidgets: 4).validate(
      withWidgets(many),
    );

    expect(result.errors.single.path, 'widgets');
  });
}
