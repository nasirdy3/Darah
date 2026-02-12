import 'package:flutter/services.dart';

// Lightweight audio stub.
// For a production release, switch to a plugin like `audioplayers`.
// We keep this project dependency-light for GitHub Actions builds.
//
// NOTE: This stub only triggers haptics and does not play actual audio.
// It is here so the game code remains structured.

class AudioManager {
  const AudioManager();

  Future<void> playPlace() async => HapticFeedback.lightImpact();
  Future<void> playMove() async => HapticFeedback.selectionClick();
  Future<void> playWin() async => HapticFeedback.mediumImpact();
  Future<void> playLose() async => HapticFeedback.heavyImpact();
}
