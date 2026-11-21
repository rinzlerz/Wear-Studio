import 'package:flutter/widgets.dart';

import 'built_in_themes.dart';
import 'watch_theme.dart';

/// Makes a [WatchTheme] available to the widgets below it.
class WatchThemeScope extends InheritedWidget {
  const WatchThemeScope({super.key, required this.theme, required super.child});

  final WatchTheme theme;

  /// The nearest theme, or Minimalist when there is none.
  static WatchTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WatchThemeScope>()?.theme ??
      BuiltInThemes.minimalist;

  @override
  bool updateShouldNotify(WatchThemeScope oldWidget) =>
      theme != oldWidget.theme;
}
