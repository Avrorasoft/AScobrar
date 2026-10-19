import 'package:just_audio/just_audio.dart';

class AudioManager {
  static final AudioPlayer _effectPlayer = AudioPlayer();
  static final AudioPlayer _bgPlayer = AudioPlayer();

  static Future<void> playEffect(String assetPath) async {
    try {
      await _effectPlayer.setAsset(assetPath);
      await _effectPlayer.play();
    } catch (_) {}
  }

  static Future<void> playBackground(String assetPath) async {
    try {
      await _bgPlayer.setAsset(assetPath);
      await _bgPlayer.setLoopMode(LoopMode.one);
      await _bgPlayer.play();
    } catch (_) {}
  }

  static Future<void> stopBackground() async {
    try {
      await _bgPlayer.stop();
    } catch (_) {}
  }
}
