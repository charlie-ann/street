import 'package:street/core/sound_manager.dart';

class AudioManager {
  static Future<void> initialize() async {
    // Initialize using existing SoundManager
  }

  static Future<void> playDiceSound({double volume = 1.0}) async {
    SoundManager().playDice();
  }

  static Future<void> dispose() async {
    // Cleanup if needed
  }
} 