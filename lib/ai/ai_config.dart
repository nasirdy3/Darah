enum AiTier { beginner, amateur, pro, master, grandmaster, impossible }

extension AiTierX on AiTier {
  String get id => switch (this) {
        AiTier.beginner => 'beginner',
        AiTier.amateur => 'amateur',
        AiTier.pro => 'pro',
        AiTier.master => 'master',
        AiTier.grandmaster => 'grandmaster',
        AiTier.impossible => 'impossible',
      };

  String get label => switch (this) {
        AiTier.beginner => 'Beginner',
        AiTier.amateur => 'Amateur',
        AiTier.pro => 'Pro',
        AiTier.master => 'Master',
        AiTier.grandmaster => 'Grandmaster',
        AiTier.impossible => 'Impossible',
      };

  static AiTier fromId(String id) {
    switch (id) {
      case 'beginner':
        return AiTier.beginner;
      case 'amateur':
        return AiTier.amateur;
      case 'pro':
        return AiTier.pro;
      case 'master':
        return AiTier.master;
      case 'grandmaster':
        return AiTier.grandmaster;
      case 'impossible':
        return AiTier.impossible;
      default:
        return AiTier.amateur;
    }
  }
}

class AiProfile {
  const AiProfile({
    required this.tier,
    required this.level,
    required this.playerAggression,
    required this.playerHeat,
    required this.boardSize,
  });

  final AiTier tier;
  final int level;
  final double playerAggression;
  final List<int> playerHeat;
  final int boardSize;
}

class AiSearchConfig {
  const AiSearchConfig({
    required this.depth,
    required this.timeMs,
    required this.randomness,
    required this.aggressionBias,
  });

  final int depth;
  final int timeMs;
  final double randomness;
  final double aggressionBias;
}

AiSearchConfig configFor(AiProfile profile, {required bool isPlacement}) {
  final lvl = profile.level.clamp(1, 300);
  final tier = profile.tier;

  int depthBase;
  int timeMs;
  double randomness;

  switch (tier) {
    case AiTier.beginner:
      depthBase = isPlacement ? 1 : 2;
      timeMs = 180;
      randomness = 0.35;
      break;
    case AiTier.amateur:
      depthBase = isPlacement ? 2 : 3;
      timeMs = 320;
      randomness = 0.22;
      break;
    case AiTier.pro:
      depthBase = isPlacement ? 3 : 4;
      timeMs = 520;
      randomness = 0.14;
      break;
    case AiTier.master:
      depthBase = isPlacement ? 4 : 5;
      timeMs = 760;
      randomness = 0.08;
      break;
    case AiTier.grandmaster:
      depthBase = isPlacement ? 5 : 6;
      timeMs = 1000;
      randomness = 0.04;
      break;
    case AiTier.impossible:
      depthBase = isPlacement ? 6 : 7;
      timeMs = 1400;
      randomness = 0.0;
      break;
  }

  final bonus = (lvl / 60).floor();
  final depth = (depthBase + bonus).clamp(depthBase, depthBase + 2);

  final aggressionBias = tier == AiTier.impossible
      ? profile.playerAggression
      : (0.35 + tier.index * 0.1).clamp(0.0, 1.0);

  return AiSearchConfig(
    depth: depth,
    timeMs: timeMs,
    randomness: randomness,
    aggressionBias: aggressionBias,
  );
}
