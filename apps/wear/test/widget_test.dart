import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wear_studio_core/wear_studio_core.dart';
import 'package:wear_studio_platform/wear_studio_platform.dart';
import 'package:wear_studio_widget_engine/wear_studio_widget_engine.dart'
    show PhoneLinkState;
import 'package:wear_studio_wear/src/app.dart';
import 'package:wear_studio_wear/src/data/profile_store.dart';
import 'package:wear_studio_wear/src/features/watch/watch_controller.dart';
import 'package:wear_studio_wear/src/providers.dart';

class FakeDataLayer implements DataLayer {
  FakeDataLayer({this.items = const [], this.phones = const []});

  final List<WearDataItem> items;
  final List<WearNode> phones;
  final events$ = StreamController<WearEvent>.broadcast();
  final sentMessages = <(String, String, Uint8List)>[];

  @override
  Stream<WearEvent> get events => events$.stream;

  @override
  Future<List<WearNode>> capableNodes(String capability) async => phones;

  @override
  Future<List<WearNode>> connectedNodes() async => phones;

  @override
  Future<List<WearDataItem>> dataItems(String path) async => items;

  @override
  Future<WearNode> localNode() async =>
      const WearNode(id: 'watch', displayName: 'Watch', isNearby: true);

  @override
  Future<void> putData(String path, Uint8List data,
      {bool urgent = true}) async {}

  @override
  Future<void> sendMessage(String nodeId, String path, Uint8List data) async =>
      sentMessages.add((nodeId, path, data));
}

const phone = WearNode(id: 'p1', displayName: 'Phone', isNearby: true);

class FakeBatterySource implements BatterySource {
  @override
  Future<BatteryStatus> read() async =>
      const BatteryStatus(level: 77, charging: false);
}

ProviderContainer containerWith(FakeDataLayer fake, MemoryProfileStore store) {
  final container = ProviderContainer(
    overrides: [
      dataLayerProvider.overrideWithValue(fake),
      profileStoreProvider.overrideWithValue(store),
      batterySourceProvider.overrideWithValue(FakeBatterySource()),
      deviceInfoProvider.overrideWith((ref) async => WearDeviceInfo.unknown),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

WearDataEvent profileEvent(int revision, WatchProfile profile) => WearDataEvent(
      path: SyncPaths.activeProfile,
      sourceNodeId: 'p1',
      data: SyncEnvelope.profile(profile, revision: revision).encode(),
      deleted: false,
    );

void main() {
  test('restores the stored profile while offline', () async {
    final store = MemoryProfileStore(StoredProfile(SampleProfiles.minimal, 5));
    final container = containerWith(FakeDataLayer(), store);

    container.read(watchControllerProvider);
    await settle();

    final state = container.read(watchControllerProvider);
    expect(state.profile, SampleProfiles.minimal);
    expect(state.revision, 5);
    expect(state.phoneLink, PhoneLinkState.disconnected);
  });

  test('catches up from Data Layer items and persists them', () async {
    final store = MemoryProfileStore(StoredProfile(SampleProfiles.minimal, 5));
    final item = WearDataItem(
      path: SyncPaths.activeProfile,
      sourceNodeId: 'p1',
      data:
          SyncEnvelope.profile(SampleProfiles.prdExample, revision: 6).encode(),
    );
    final container = containerWith(FakeDataLayer(items: [item]), store);

    container.read(watchControllerProvider);
    await settle();

    expect(container.read(watchControllerProvider).profile,
        SampleProfiles.prdExample);
    expect(store.stored!.revision, 6);
  });

  test('applies newer profiles and ignores redelivered or older ones',
      () async {
    final fake = FakeDataLayer(phones: [phone]);
    final store = MemoryProfileStore();
    final container = containerWith(fake, store);
    container.read(watchControllerProvider);
    await settle();

    fake.events$.add(profileEvent(10, SampleProfiles.prdExample));
    await settle();
    fake.events$.add(profileEvent(10, SampleProfiles.minimal)); // redelivery
    fake.events$.add(profileEvent(9, SampleProfiles.minimal)); // stale
    await settle();

    final state = container.read(watchControllerProvider);
    expect(state.profile, SampleProfiles.prdExample);
    expect(state.revision, 10);
    expect(store.stored!.profile, SampleProfiles.prdExample);
  });

  test('keeps the current profile when an invalid one arrives', () async {
    final fake = FakeDataLayer();
    final store = MemoryProfileStore(StoredProfile(SampleProfiles.minimal, 1));
    final container = containerWith(fake, store);
    container.read(watchControllerProvider);
    await settle();

    final widget = SampleProfiles.minimal.widgets.first;
    final invalid = SampleProfiles.minimal.copyWith(widgets: [widget, widget]);
    fake.events$.add(profileEvent(2, invalid));
    await settle();

    expect(container.read(watchControllerProvider).revision, 1);
  });

  test('answers pings from the phone', () async {
    final fake = FakeDataLayer(phones: [phone]);
    final container = containerWith(fake, MemoryProfileStore());
    container.read(watchControllerProvider);
    await settle();

    fake.events$.add(WearMessageEvent(
      path: SyncPaths.ping,
      sourceNodeId: 'p1',
      data: SyncEnvelope.ping('xyz').encode(),
    ));
    await settle();

    final (nodeId, path, bytes) = fake.sentMessages.single;
    expect(nodeId, 'p1');
    expect(path, SyncPaths.pong);
    expect(SyncEnvelope.decode(bytes).pingId, 'xyz');
  });

  testWidgets('renders the stored profile with live data', (tester) async {
    final store = MemoryProfileStore(StoredProfile(SampleProfiles.minimal, 1));
    final container = containerWith(FakeDataLayer(phones: [phone]), store);
    tester.view.physicalSize = const Size(454, 454);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WearApp()),
    );
    await tester.pump();
    await tester.pump();

    for (final w in SampleProfiles.minimal.widgets) {
      expect(find.byKey(ValueKey(w.widgetId)), findsOneWidget);
    }
    expect(find.text('Phone'), findsOneWidget); // system status widget
    expect(find.text('77%'), findsOneWidget); // battery widget
  });

  testWidgets('shows the default layout before any profile arrives',
      (tester) async {
    final container = containerWith(FakeDataLayer(), MemoryProfileStore());
    tester.view.physicalSize = const Size(454, 454);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WearApp()),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('clock_001')), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
  });

  testWidgets('a new profile from the phone switches theme and layout',
      (tester) async {
    final fake = FakeDataLayer(phones: [phone]);
    final container = containerWith(fake, MemoryProfileStore());
    tester.view.physicalSize = const Size(454, 454);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const WearApp()),
    );
    await tester.pump();

    fake.events$.add(profileEvent(5, SampleProfiles.hacker));
    await tester.pump();
    await tester.pump();

    expect(
        container.read(watchControllerProvider).profile, SampleProfiles.hacker);
    // Hacker uses the text-style battery widget.
    expect(find.text('77%'), findsOneWidget);
    expect(find.byKey(const ValueKey('status_001')), findsOneWidget);
  });
}
