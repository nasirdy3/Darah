class LevelDefinition {
  const LevelDefinition({
    required this.id,
    required this.name,
    required this.boardSize,
    required this.aiTier,
    required this.aiLevel,
  });

  final int id;
  final String name;
  final int boardSize;
  final String aiTier;
  final int aiLevel;
}

final List<LevelDefinition> levels = List.generate(60, (i) {
  final id = i + 1;
  final boardSize = id <= 20 ? 5 : 6;
  String tier;
  if (id <= 10) {
    tier = 'beginner';
  } else if (id <= 20) {
    tier = 'amateur';
  } else if (id <= 30) {
    tier = 'pro';
  } else if (id <= 40) {
    tier = 'master';
  } else if (id <= 50) {
    tier = 'grandmaster';
  } else {
    tier = 'impossible';
  }

  final aiLevel = (6 + id * 2).clamp(1, 300);

  return LevelDefinition(
    id: id,
    name: 'Level $id',
    boardSize: boardSize,
    aiTier: tier,
    aiLevel: aiLevel,
  );
});
