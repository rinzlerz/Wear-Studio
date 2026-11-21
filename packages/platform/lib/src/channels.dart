import 'package:flutter/services.dart';

/// Channel names. Must match `WearStudioPlatformPlugin.kt`.
abstract final class WearStudioChannels {
  static const methodName = 'com.wearstudio/platform';
  static const eventsName = 'com.wearstudio/platform/events';

  static const method = MethodChannel(methodName);
  static const events = EventChannel(eventsName);
}
