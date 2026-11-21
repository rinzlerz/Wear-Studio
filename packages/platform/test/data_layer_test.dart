import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wear_studio_platform/wear_studio_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = WearStudioChannels.method;
  final calls = <MethodCall>[];

  void mockHandler(Future<Object?>? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(calls.clear);
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('connectedNodes parses node maps', () async {
    mockHandler((call) async => [
          {'id': 'n1', 'displayName': 'Pixel Watch', 'isNearby': true},
          {'id': 'n2'},
        ]);

    final nodes = await MethodChannelDataLayer().connectedNodes();

    expect(nodes, const [
      WearNode(id: 'n1', displayName: 'Pixel Watch', isNearby: true),
      WearNode(id: 'n2', displayName: 'n2', isNearby: false),
    ]);
    expect(calls.single.method, 'getConnectedNodes');
  });

  test('capableNodes passes the capability name', () async {
    mockHandler((call) async => <Object?>[]);

    await MethodChannelDataLayer().capableNodes('wear_studio_watch');

    expect(calls.single.arguments, {'capability': 'wear_studio_watch'});
  });

  test('putData sends path, bytes and urgency', () async {
    mockHandler((call) async => null);

    await MethodChannelDataLayer().putData('/p', Uint8List.fromList([1, 2]));

    final args = calls.single.arguments as Map<Object?, Object?>;
    expect(args['path'], '/p');
    expect(args['data'], Uint8List.fromList([1, 2]));
    expect(args['urgent'], isTrue);
  });

  test('native errors become DataLayerException', () async {
    mockHandler((call) async {
      throw PlatformException(code: 'unavailable', message: 'no wearable api');
    });

    await expectLater(
      MethodChannelDataLayer().connectedNodes(),
      throwsA(isA<DataLayerException>()
          .having((e) => e.isUnavailable, 'isUnavailable', isTrue)),
    );
  });

  test('missing plugin is reported as unavailable', () async {
    // No handler registered => MissingPluginException.
    await expectLater(
      MethodChannelDataLayer().connectedNodes(),
      throwsA(isA<DataLayerException>()
          .having((e) => e.isUnavailable, 'isUnavailable', isTrue)),
    );
  });

  test('device info falls back to unknown without the plugin', () async {
    final info = await MethodChannelDeviceInfo().load();

    expect(info.isWatch, isFalse);
    expect(info.model, 'unknown');
  });

  test('battery status is parsed and falls back to unknown', () async {
    mockHandler((call) async => {'level': 64, 'charging': true});
    final status = await MethodChannelBatterySource().read();
    expect(status.level, 64);
    expect(status.charging, isTrue);

    messenger.setMockMethodCallHandler(channel, null);
    final fallback = await MethodChannelBatterySource().read();
    expect(fallback.level, isNull);
  });
}
