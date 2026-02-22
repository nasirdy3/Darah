import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioManager instance = AudioManager._internal();
  AudioManager._internal();

  final AudioPlayer _effectPlayer = AudioPlayer();
  bool _enabled = true;

  void toggleSound(bool value) {
    _enabled = value;
  }

  Future<void> playSfx(String name) async {
    if (!_enabled) return;
    try {
      await _effectPlayer.play(AssetSource('audio/$name.mp3'));
    } catch (e) {
      // Audio might fail in some environments
    }
  }

  void playPlace() => playSfx('place');
  void playMove() => playSfx('move');
  void playCapture() => playSfx('capture');
  void playWin() => playSfx('win');
  void playError() => playSfx('error');
}
