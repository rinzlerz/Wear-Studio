import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wear_studio_companion/src/app.dart';
import 'package:wear_studio_companion/src/features/connection/connection_controller.dart';
import 'package:wear_studio_companion/src/providers.dart';
import 'package:wear_studio_core/wear_studio_core.dart';
import 'package:wear_studio_platform/wear_studio_platform.dart';

class FakeDataLayer implements DataLayer {
  FakeDataLayer({this.watches = const []});

  final List<WearNode> watches;
  final events$ = StreamController<WearEvent>.broadcast();
  final sentMessages = <(String, String, Uint8List)>[];
  final putItems = <(String, Uint8List)>[];

  @override
  Stream<WearEvent> get events => events$.stream;

  @override
  Future<List<WearNode>> capableNodes(String capability) async => watches;

  @override
  Future<List<WearNode>> connectedNodes() async => watches;

  @override
  Future<List<WearDataItem>> dataItems(String path) async => const [];

  @override
  Future<WearNode> localNode() async =>
      const WearNode(id: 'phone', displayName: 'Phone', isNearby: true);

  @override
  Future<void> putData(String path, Uint8List data,
          {bool urgent = true}) async =>
      putItems.add((path, data));

  @override
  Future<void> sendMessage(String nodeId, String path, Uint8List data) async =>
      sentMessages.add((nodeId, path, data));
}

const watch = WearNode(id: 'w1', displayName: 'Galaxy Watch', isNearby: true);

ProviderContainer containerWith(FakeDataLayer fake) {
  final container = ProviderContainer(
    overrides: [
      dataLayerProvider.overrideWithValue(fake),
      deviceInfoProvider.overrideWith((ref) async => WearDeviceInfo.unknown),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  testWidgets('shows the discovered watch', (tester) async {
    final container = containerWith(FakeDataLayer(watches: [watch]));

    await tester.pumpWidget(
      UncontrolledProviderScope(
          container: container, child: const CompanionApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Galaxy Watch'), findsOneWidget);
    expect(find.text('Ping watch'), findsOneWidget);
  });

  testWidgets('explains when no watch app is installed', (tester) async {
    final container = containerWith(FakeDataLayer());

    await tester.pumpWidget(
      UncontrolledProviderScope(
          container: container, child: const CompanionApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('No watch with Wear Studio found'), findsOneWidget);
  });

  test('pushProfile publishes a decodable envelope', () async {
    final fake = FakeDataLayer(watches: [watch]);
    final container = containerWith(fake);
    final controller = container.read(companionControllerProvider.notifier);

    await controller.pushProfile(SampleProfiles.minimal);

    final (path, bytes) = fake.putItems.single;
    expect(path, SyncPaths.activeProfile);
    expect(SyncEnvelope.decode(bytes).profile, SampleProfiles.minimal);
  });

  test('answers a ping from the watch with a pong', () async {
    final fake = FakeDataLayer(watches: [watch]);
    final container = containerWith(fake);
    container.read(companionControllerProvider); // start listening
    await Future<void>.delayed(Duration.zero);

    fake.events$.add(WearMessageEvent(
      path: SyncPaths.ping,
      sourceNodeId: 'w1',
      data: SyncEnvelope.ping('abc').encode(),
    ));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final (nodeId, path, bytes) = fake.sentMessages.single;
    expect(nodeId, 'w1');
    expect(path, SyncPaths.pong);
    expect(SyncEnvelope.decode(bytes).pingId, 'abc');
  });
}
