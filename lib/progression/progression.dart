import 'levels.dart';

int calculateStars({required bool win, required int usedHints, required int usedUndos}) {
  if (!win) return 0;
  if (usedHints == 0 && usedUndos == 0) return 3;
  if (usedHints == 0 || usedUndos == 0) return 2;
  return 1;
}

int coinsForWin({LevelDefinition? level, required int stars}) {
  final base = level == null ? 40 : (60 + level.id * 3);
  final bonus = switch (stars) {
    3 => 120,
    2 => 60,
    1 => 20,
    _ => 0,
  };
  return base + bonus;
}
