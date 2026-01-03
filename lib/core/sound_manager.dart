import 'package:just_audio/just_audio.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  late final AudioPlayer _dicePlayer;
  late final AudioPlayer _movePlayer;
  late final AudioPlayer _capturePlayer;
  late final AudioPlayer _winPlayer;

  Future<void> init() async {
    _dicePlayer = AudioPlayer();
    _movePlayer = AudioPlayer();
    _capturePlayer = AudioPlayer();
    _winPlayer = AudioPlayer();
  }

  void playDice() async {
    try {
      await _dicePlayer.setAsset('assets/sounds/dice_roll.mp3');
      _dicePlayer.play();
    } catch (e) {
      // Fallback to haptic feedback if audio fails
      // HapticFeedback.lightImpact();
    }
  }

  void playMove() async {
    try {
      await _movePlayer.setAsset('assets/sounds/piece_move.mp3');
      _movePlayer.play();
    } catch (e) {
      // Fallback to haptic feedback if audio fails
      // HapticFeedback.selectionClick();
    }
  }

  void playCapture() async {
    try {
      await _capturePlayer.setAsset('assets/sounds/capture.mp3');
      _capturePlayer.play();
    } catch (e) {
      // Fallback to haptic feedback if audio fails
      // HapticFeedback.mediumImpact();
    }
  }

  void playWin() async {
    try {
      await _winPlayer.setAsset('assets/sounds/win.mp3');
      _winPlayer.play();
    } catch (e) {
      // Fallback to haptic feedback if audio fails
      // HapticFeedback.heavyImpact();
    }
  }

  void dispose() {
    _dicePlayer.dispose();
    _movePlayer.dispose();
    _capturePlayer.dispose();
    _winPlayer.dispose();
  }
}