/// Wear OS Data Layer paths used by Wear Studio (PRD §3.3).
///
/// * Data items (DataClient) hold persistent, synchronized state.
/// * Messages (MessageClient) are fire-and-forget commands.
abstract final class SyncPaths {
  static const _root = '/wear-studio';

  /// Data item: the active profile wrapped in a SyncEnvelope.
  static const activeProfile = '$_root/profile/active';

  /// Message: liveness check; the receiver answers on [pong].
  static const ping = '$_root/ping';

  /// Message: answer to [ping].
  static const pong = '$_root/pong';
}

/// Capability names advertised in each app's `res/values/wear.xml`.
/// Used to find the node that actually has the other Wear Studio app.
abstract final class WearCapabilities {
  static const companion = 'wear_studio_companion';
  static const watch = 'wear_studio_watch';
}
