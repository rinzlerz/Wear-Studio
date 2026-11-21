import 'package:flutter/widgets.dart';
import 'package:wear_studio_theme_engine/wear_studio_theme_engine.dart';

/// Shown for widget types this device cannot render yet (for example a
/// profile created by a newer phone app). Keeps the rest of the layout
/// working instead of failing the whole profile.
class UnknownWidgetView extends StatelessWidget {
  const UnknownWidgetView({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = WatchThemeScope.of(context);
    return Center(
      child: FittedBox(
        child: Text(
          type,
          style: theme.text(10, color: theme.secondary),
        ),
      ),
    );
  }
}
