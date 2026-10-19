import 'package:just_audio/just_audio.dart';

class AppSounds {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> success() async {
    try {
      await _player.setAsset('assets/sounds/success.mp3');
      await _player.play();
    } catch (_) {}
  }

  static Future<void> newClient() async => await success();

  static Future<void> warning() async {
    try {
      await _player.setAsset('assets/sounds/warning.mp3');
      await _player.play();
    } catch (_) {}
  }

  static Future<void> ownerNotify() async {
    try {
      await _player.setAsset('assets/sounds/notify.mp3');
      await _player.play();
    } catch (_) {}
  }
}
