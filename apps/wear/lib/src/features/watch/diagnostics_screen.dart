import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../ui/round_safe_area.dart';
import 'watch_controller.dart';

/// Values to record in the Phase 1 feasibility report.
/// Open with a long press on the main screen; swipe right / back to leave.
class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(watchControllerProvider);
    final info = ref.watch(deviceInfoProvider).value;
    final size = MediaQuery.sizeOf(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final small = Theme.of(context).textTheme.bodySmall;

    final lines = [
      if (info != null) ...[
        '${info.manufacturer} ${info.model}',
        'API ${info.sdkInt} · watch ${info.isWatch} · round ${info.isScreenRound}',
      ],
      'Logical ${size.width.toStringAsFixed(0)}×${size.height.toStringAsFixed(0)} '
          '@${ratio.toStringAsFixed(2)}x',
      'Profile rev ${state.revision ?? '-'}',
      'Phone ${state.phoneLink.name}',
      if (state.lastSyncAt != null) 'Last sync ${state.lastSyncAt}',
      '',
      ...state.log,
    ];

    return Scaffold(
      body: RoundSafeArea(
        round: info?.isScreenRound ?? true,
        child: ListView(
          children: [
            Center(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => setState(() => _taps++),
                  child: Text('Touch test: $_taps'),
                ),
              ),
            ),
            for (final line in lines) Text(line, style: small),
          ],
        ),
      ),
    );
  }
}
