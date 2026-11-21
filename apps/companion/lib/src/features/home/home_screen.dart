import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wear_studio_core/wear_studio_core.dart';

import '../../providers.dart';
import '../connection/connection_controller.dart';

/// Phase 1 home: connection status and the feasibility test actions.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companionControllerProvider);
    final controller = ref.read(companionControllerProvider.notifier);
    final hasWatch = state.selectedWatch != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wear Studio'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: state.loading ? null : controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _WatchCard(state: state, onSelect: controller.selectWatch),
            const SizedBox(height: 16),
            Text('Test actions',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: hasWatch ? controller.ping : null,
                  icon: const Icon(Icons.wifi_tethering),
                  label: const Text('Ping watch'),
                ),
                for (final profile in SampleProfiles.all)
                  FilledButton.tonalIcon(
                    onPressed: () => controller.pushProfile(profile),
                    icon: const Icon(Icons.upload),
                    label: Text('Send "${profile.profileName}"'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              [
                if (state.lastRoundTrip != null)
                  'Last round trip: ${state.lastRoundTrip!.inMilliseconds} ms',
                if (state.lastPushedRevision != null)
                  'Last published revision: ${state.lastPushedRevision}',
              ].join('\n'),
            ),
            const SizedBox(height: 16),
            const _DeviceInfoTile(),
            const Divider(),
            Text('Log', style: Theme.of(context).textTheme.titleMedium),
            for (final entry in state.log) _LogLine(entry),
          ],
        ),
      ),
    );
  }
}

class _WatchCard extends StatelessWidget {
  const _WatchCard({required this.state, required this.onSelect});

  final CompanionState state;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget body;
    if (state.loading && state.watches.isEmpty) {
      body = const ListTile(
        leading: CircularProgressIndicator(),
        title: Text('Looking for your watch...'),
      );
    } else if (state.unavailableReason != null) {
      body = ListTile(
        leading: Icon(Icons.error_outline, color: scheme.error),
        title: const Text('Wear OS unavailable'),
        subtitle: Text(state.unavailableReason!),
      );
    } else if (state.watches.isEmpty) {
      body = ListTile(
        leading: const Icon(Icons.watch_off_outlined),
        title: const Text('No watch with Wear Studio found'),
        subtitle: Text(
          state.connectedNodes.isEmpty
              ? 'No paired watch is connected.'
              : 'Connected: ${state.connectedNodes.map((n) => n.displayName).join(', ')}.\n'
                  'Install the Wear Studio watch app on it.',
        ),
      );
    } else {
      body = Column(
        children: [
          for (final watch in state.watches)
            ListTile(
              leading: Icon(
                Icons.watch,
                color:
                    watch.id == state.selectedWatchId ? scheme.primary : null,
              ),
              title: Text(watch.displayName),
              subtitle: Text(
                  watch.isNearby ? 'Connected nearby' : 'Reachable via cloud'),
              trailing: watch.id == state.selectedWatchId
                  ? const Icon(Icons.check_circle)
                  : null,
              onTap: () => onSelect(watch.id),
            ),
        ],
      );
    }
    return Card(child: body);
  }
}

class _DeviceInfoTile extends ConsumerWidget {
  const _DeviceInfoTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(deviceInfoProvider);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.phone_android),
      title: const Text('This phone'),
      subtitle: Text(info.when(
        data: (i) => i.toString(),
        loading: () => '...',
        error: (e, _) => 'unknown ($e)',
      )),
    );
  }
}

class _LogLine extends StatelessWidget {
  const _LogLine(this.entry);

  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = entry.time;
    String two(int v) => v.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}  ${entry.message}',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: entry.isError ? Theme.of(context).colorScheme.error : null,
        ),
      ),
    );
  }
}
