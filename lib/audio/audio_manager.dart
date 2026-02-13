import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../state/settings_store.dart';

class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();

  bool _initialized = false;
  late SettingsStore _settings;

  Future<void> init(SettingsStore settings) async {
    _settings = settings;
    if (_initialized) {
      await sync(settings);
      return;
    }
    _initialized = true;
    await _music.setReleaseMode(ReleaseMode.loop);
    await _music.setVolume(0.35);
    if (_settings.musicOn) {
      await _music.play(AssetSource('audio/music_bg.wav'));
    }
  }

  Future<void> sync(SettingsStore settings) async {
    _settings = settings;
    if (_settings.musicOn) {
      if (_music.state != PlayerState.playing) {
        await _music.play(AssetSource('audio/music_bg.wav'));
      }
    } else {
      await _music.stop();
    }
  }

  Future<void> dispose() async {
    await _sfx.dispose();
    await _music.dispose();
  }

  Future<void> playSelect() async {
    if (_settings.hapticsOn) HapticFeedback.selectionClick();
  }

  Future<void> playPlace() async {
    if (_settings.hapticsOn) HapticFeedback.lightImpact();
    await _playSfx('audio/s_place.wav', volume: 0.9);
  }

  Future<void> playMove() async {
    if (_settings.hapticsOn) HapticFeedback.selectionClick();
    await _playSfx('audio/s_move.wav', volume: 0.85);
  }

  Future<void> playCapture() async {
    if (_settings.hapticsOn) HapticFeedback.mediumImpact();
    await _playSfx('audio/s_move.wav', volume: 1.0);
  }

  Future<void> playWin() async {
    if (_settings.hapticsOn) HapticFeedback.heavyImpact();
    await _playSfx('audio/s_win.wav', volume: 1.0);
  }

  Future<void> playLose() async {
    if (_settings.hapticsOn) HapticFeedback.vibrate();
    await _playSfx('audio/s_lose.wav', volume: 0.9);
  }

  Future<void> _playSfx(String asset, {double volume = 1.0}) async {
    if (!_settings.soundOn) return;
    await _sfx.play(AssetSource(asset), volume: volume);
  }
}
