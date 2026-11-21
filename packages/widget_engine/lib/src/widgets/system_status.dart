import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:wear_studio_core/wear_studio_core.dart';
import 'package:wear_studio_theme_engine/wear_studio_theme_engine.dart';

import '../environment.dart';
import '../widget_definition.dart';

class SystemStatusDefinition extends WatchWidgetDefinition {
  const SystemStatusDefinition();

  @override
  String get type => BuiltInWidgetTypes.systemStatus;

  @override
  String get displayName => 'System status';

  @override
  NormalizedSize get defaultSize => const NormalizedSize(0.4, 0.09);

  @override
  SizeLimits get sizeLimits => const SizeLimits(minWidth: 0.1, minHeight: 0.06);

  @override
  List<SettingField> get settings => const [
        BoolSetting('showLabel', 'Show label', defaultValue: true),
      ];

  @override
  Widget build(BuildContext context, WatchWidgetContext widget) =>
      SystemStatusView(
        theme: widget.theme,
        showLabel: widget.settings['showLabel'] == true,
      );
}

class SystemStatusView extends StatelessWidget {
  const SystemStatusView(
      {super.key, required this.theme, this.showLabel = true});

  final WatchTheme theme;
  final bool showLabel;

  /// Icon and label for each state.
  static (IconData, String) describe(PhoneLinkState state) => switch (state) {
        PhoneLinkState.connected => (Icons.smartphone, 'Phone'),
        PhoneLinkState.disconnected => (Icons.phonelink_erase, 'Offline'),
        PhoneLinkState.unavailable => (Icons.error_outline, 'No Wear API'),
        PhoneLinkState.unknown => (Icons.sync, 'Connecting'),
      };

  @override
  Widget build(BuildContext context) {
    final link = WatchEnvironmentScope.of(context).phoneLink;
    return ValueListenableBuilder<PhoneLinkState>(
      valueListenable: link,
      builder: (context, state, _) {
        final (icon, label) = describe(state);
        final color =
            state == PhoneLinkState.connected ? theme.primary : theme.accent;
        return FittedBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14 * theme.fontScale),
              if (showLabel) ...[
                const SizedBox(width: 4),
                Text(label, style: theme.text(12, color: color)),
              ],
            ],
          ),
        );
      },
    );
  }
}
