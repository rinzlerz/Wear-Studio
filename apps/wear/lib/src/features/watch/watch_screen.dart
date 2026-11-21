import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wear_studio_core/wear_studio_core.dart';

import '../../providers.dart';
import '../../ui/live_clock.dart';
import '../../ui/round_safe_area.dart';
import 'watch_controller.dart';

/// Phase 1 watch screen: time and date, sync status, and a ping test.
///
/// The configurable widget layout replaces the centre of this screen in
/// Phase 2 (UI rendering engine).
class WatchScreen extends ConsumerWidget {
  const WatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(watchControllerProvider);
    final controller = ref.read(watchControllerProvider.notifier);
    final round = ref.watch(deviceInfoProvider).value?.isScreenRound ?? true;
    final scheme = Theme.of(context).colorScheme;
    final profile = state.profile;

    final clockSettings = profile?.widgets
        .where((w) => w.type == BuiltInWidgetTypes.digitalClock)
        .firstOrNull
        ?.settings;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => context.push('/diagnostics'),
        child: RoundSafeArea(
          round: round,
          // scaleDown keeps everything visible on the smallest watches.
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LinkIndicator(link: state.phoneLink),
                  const SizedBox(height: 4),
                  LiveClock(
                    use24h: clockSettings?['format'] != '12h',
                    showDate: clockSettings?['showDate'] != false,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile == null
                        ? 'No profile yet'
                        : '${profile.profileName} · ${profile.widgets.length} widgets',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 48dp minimum touch target, per Wear OS guidance.
                  SizedBox(
                    height: 48,
                    child: FilledButton.tonal(
                      onPressed: controller.pingPhone,
                      child: Text(
                        state.lastRoundTrip == null
                            ? 'Ping phone'
                            : 'Ping · ${state.lastRoundTrip!.inMilliseconds} ms',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkIndicator extends StatelessWidget {
  const _LinkIndicator({required this.link});

  final PhoneLink link;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (link) {
      PhoneLink.connected => (
          Icons.phone_android,
          'Phone connected',
          Colors.tealAccent
        ),
      PhoneLink.disconnected => (
          Icons.phonelink_erase,
          'Offline',
          Colors.orangeAccent
        ),
      PhoneLink.unavailable => (
          Icons.error_outline,
          'No Wear API',
          Colors.redAccent
        ),
      PhoneLink.unknown => (Icons.sync, 'Connecting', Colors.grey),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
