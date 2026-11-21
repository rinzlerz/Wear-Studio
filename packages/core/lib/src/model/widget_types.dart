/// Registry keys for the built-in widgets listed in PRD FR-003.
///
/// These are identifiers only. Rendering and behaviour live in the widget
/// registry (Phase 2), so adding a type here never changes the engine.
abstract final class BuiltInWidgetTypes {
  static const digitalClock = 'digital_clock';
  static const battery = 'battery';
  static const weather = 'weather';
  static const music = 'music';
  static const audioVisualizer = 'audio_visualizer';
  static const systemStatus = 'system_status';
  static const phoneIntegration = 'phone_integration';
  static const aiAssistant = 'ai_assistant';
  static const smartHome = 'smart_home';

  static const all = <String>{
    digitalClock,
    battery,
    weather,
    music,
    audioVisualizer,
    systemStatus,
    phoneIntegration,
    aiAssistant,
    smartHome,
  };
}
