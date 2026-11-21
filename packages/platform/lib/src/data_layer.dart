import 'dart:async';

import 'package:flutter/services.dart';

import 'channels.dart';

/// A device in the Wear OS network (phone or watch).
class WearNode {
  const WearNode({
    required this.id,
    required this.displayName,
    required this.isNearby,
  });

  factory WearNode.fromMap(Map<Object?, Object?> map) {
    final id = map['id']! as String;
    return WearNode(
      id: id,
      displayName: (map['displayName'] as String?) ?? id,
      isNearby: (map['isNearby'] as bool?) ?? false,
    );
  }

  final String id;
  final String displayName;

  /// True when directly connected (Bluetooth) rather than via the cloud.
  final bool isNearby;

  @override
  bool operator ==(Object other) =>
      other is WearNode &&
      other.id == id &&
      other.displayName == displayName &&
      other.isNearby == isNearby;

  @override
  int get hashCode => Object.hash(id, displayName, isNearby);

  @override
  String toString() => 'WearNode($displayName, $id, nearby: $isNearby)';
}

/// A persisted Data Layer item.
class WearDataItem {
  const WearDataItem({required this.path, this.sourceNodeId, this.data});

  final String path;

  /// Node that wrote the item (the URI host).
  final String? sourceNodeId;
  final Uint8List? data;
}

sealed class WearEvent {
  const WearEvent();
}

/// A MessageClient message was received.
final class WearMessageEvent extends WearEvent {
  const WearMessageEvent({
    required this.path,
    required this.sourceNodeId,
    required this.data,
  });

  final String path;
  final String sourceNodeId;
  final Uint8List data;
}

/// A DataClient item changed or was deleted (includes this node's own writes).
final class WearDataEvent extends WearEvent {
  const WearDataEvent({
    required this.path,
    required this.sourceNodeId,
    required this.data,
    required this.deleted,
  });

  final String path;
  final String? sourceNodeId;
  final Uint8List? data;
  final bool deleted;
}

class DataLayerException implements Exception {
  const DataLayerException(this.code, this.message);

  final String code;
  final String? message;

  /// The Wearable API is missing on this device (no Play services / no paired
  /// companion, or running outside Android).
  bool get isUnavailable => code == 'unavailable';

  @override
  String toString() => 'DataLayerException($code): ${message ?? ''}';
}

/// Abstraction over the Wear OS Data Layer, so app logic can be tested with
/// a fake.
abstract interface class DataLayer {
  Future<WearNode> localNode();

  Future<List<WearNode>> connectedNodes();

  /// Reachable nodes that advertise [capability] (see `res/values/wear.xml`).
  Future<List<WearNode>> capableNodes(String capability);

  Future<void> sendMessage(String nodeId, String path, Uint8List data);

  /// Writes a data item. Items are limited to about 100 KB; use assets for
  /// larger content such as wallpapers (later phase).
  Future<void> putData(String path, Uint8List data, {bool urgent = true});

  /// Items at [path] from every node.
  Future<List<WearDataItem>> dataItems(String path);

  /// Messages and data changes, delivered while the app is running.
  Stream<WearEvent> get events;
}

/// [DataLayer] implemented by the native `WearStudioPlatformPlugin`.
class MethodChannelDataLayer implements DataLayer {
  MethodChannelDataLayer({MethodChannel? method, EventChannel? eventChannel})
      : _method = method ?? WearStudioChannels.method,
        _eventChannel = eventChannel ?? WearStudioChannels.events;

  final MethodChannel _method;
  final EventChannel _eventChannel;

  @override
  late final Stream<WearEvent> events =
      _eventChannel.receiveBroadcastStream().expand<WearEvent>((raw) {
    final event = _decodeEvent(raw);
    return event == null ? const [] : [event];
  });

  @override
  Future<WearNode> localNode() async {
    final map = await _guard(() => _method.invokeMapMethod<Object?, Object?>(
          'getLocalNode',
        ));
    return WearNode.fromMap(map!);
  }

  @override
  Future<List<WearNode>> connectedNodes() =>
      _nodes(() => _method.invokeListMethod<Object?>('getConnectedNodes'));

  @override
  Future<List<WearNode>> capableNodes(String capability) => _nodes(
        () => _method.invokeListMethod<Object?>(
          'getCapableNodes',
          {'capability': capability},
        ),
      );

  @override
  Future<void> sendMessage(String nodeId, String path, Uint8List data) =>
      _guard(() => _method.invokeMethod<void>(
            'sendMessage',
            {'nodeId': nodeId, 'path': path, 'data': data},
          ));

  @override
  Future<void> putData(String path, Uint8List data, {bool urgent = true}) =>
      _guard(() => _method.invokeMethod<void>(
            'putData',
            {'path': path, 'data': data, 'urgent': urgent},
          ));

  @override
  Future<List<WearDataItem>> dataItems(String path) async {
    final list = await _guard(
      () => _method.invokeListMethod<Object?>('getDataItems', {'path': path}),
    );
    return [
      for (final raw in list ?? const <Object?>[])
        if (raw is Map<Object?, Object?>)
          WearDataItem(
            path: raw['path']! as String,
            sourceNodeId: raw['sourceNodeId'] as String?,
            data: raw['data'] as Uint8List?,
          ),
    ];
  }

  Future<List<WearNode>> _nodes(Future<List<Object?>?> Function() call) async {
    final list = await _guard(call);
    return [
      for (final raw in list ?? const <Object?>[])
        if (raw is Map<Object?, Object?>) WearNode.fromMap(raw),
    ];
  }

  static WearEvent? _decodeEvent(Object? raw) {
    if (raw is! Map<Object?, Object?>) return null;
    switch (raw['type']) {
      case 'message':
        return WearMessageEvent(
          path: raw['path']! as String,
          sourceNodeId: raw['sourceNodeId']! as String,
          data: (raw['data'] as Uint8List?) ?? Uint8List(0),
        );
      case 'dataChanged':
      case 'dataDeleted':
        return WearDataEvent(
          path: raw['path']! as String,
          sourceNodeId: raw['sourceNodeId'] as String?,
          data: raw['data'] as Uint8List?,
          deleted: raw['type'] == 'dataDeleted',
        );
      default:
        return null;
    }
  }
}

Future<T> _guard<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on PlatformException catch (e) {
    throw DataLayerException(e.code, e.message);
  } on MissingPluginException catch (e) {
    throw DataLayerException('unavailable', e.message);
  }
}
