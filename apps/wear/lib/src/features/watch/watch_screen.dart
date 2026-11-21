import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wear_studio_core/wear_studio_core.dart';
import 'package:wear_studio_widget_engine/wear_studio_widget_engine.dart';

import '../../providers.dart';
import 'environment_host.dart';
import 'watch_controller.dart';

/// The main watch screen: the active profile rendered by the widget engine.
///
/// Before any profile has been received, a built-in default layout is shown
/// so the watch is useful straight after install. Long-press opens
/// diagnostics.
class WatchScreen extends ConsumerWidget {
  const WatchScreen({super.key});

  /// Shown until the phone sends a profile.
  static const defaultProfile = SampleProfiles.minimal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(watchControllerProvider.select((s) => s.profile)) ??
            defaultProfile;
    final round = ref.watch(deviceInfoProvider).value?.isScreenRound ?? true;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => context.push('/diagnostics'),
        child: WatchEnvironmentHost(
          child: WatchFaceCanvas(
            profile: profile,
            widgets: ref.watch(widgetRegistryProvider),
            themes: ref.watch(themeRegistryProvider),
            round: round,
          ),
        ),
      ),
    );
  }
}
