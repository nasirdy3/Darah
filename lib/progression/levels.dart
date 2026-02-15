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

final List<LevelDefinition> levels = List.generate(300, (i) {
  final id = i + 1;
  // Increase board size as player progresses
  final boardSize = id <= 40 ? 5 : 6;
  
  String tier;
  if (id <= 30) {
    tier = 'beginner';
  } else if (id <= 70) {
    tier = 'amateur';
  } else if (id <= 130) {
    tier = 'pro';
  } else if (id <= 200) {
    tier = 'master';
  } else if (id <= 260) {
    tier = 'grandmaster';
  } else {
    tier = 'impossible';
  }

  // Smooth aiLevel scaling from 1 to 300
  final aiLevel = (1 + (id / 300) * 299).round().clamp(1, 350);

  return LevelDefinition(
    id: id,
    name: 'Level $id',
    boardSize: boardSize,
    aiTier: tier,
    aiLevel: aiLevel,
  );
});
