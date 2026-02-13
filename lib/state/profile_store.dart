import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ProfileStore {
  ProfileStore(this._prefs);
  final SharedPreferences _prefs;

  int coins = 0;
  int highestUnlockedLevel = 1;
  Map<int, int> levelStars = {};

  Set<String> unlockedBoards = {};
  Set<String> unlockedSeeds = {};
  Set<String> unlockedAiTiers = {};

  String equippedBoard = 'wood_classic';
  String equippedSeed = 'stone_classic';

  DateTime? lastDailyReward;

  int extraHints = 0;
  int extraUndos = 0;

  int games = 0;
  int wins = 0;
  double playerAggression = 0.5;

  List<int> heatMap5 = List<int>.filled(25, 0);
  List<int> heatMap6 = List<int>.filled(36, 0);

  Future<void> load() async {
    final raw = _prefs.getString('profile') ?? '';
    if (raw.isNotEmpty) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        coins = (data['coins'] ?? coins) as int;
        highestUnlockedLevel = (data['highestUnlockedLevel'] ?? highestUnlockedLevel) as int;
        equippedBoard = (data['equippedBoard'] ?? equippedBoard) as String;
        equippedSeed = (data['equippedSeed'] ?? equippedSeed) as String;
        extraHints = (data['extraHints'] ?? extraHints) as int;
        extraUndos = (data['extraUndos'] ?? extraUndos) as int;
        games = (data['games'] ?? games) as int;
        wins = (data['wins'] ?? wins) as int;
        playerAggression = (data['playerAggression'] ?? playerAggression).toDouble();

        final last = data['lastDailyReward'];
        if (last is String) {
          lastDailyReward = DateTime.tryParse(last);
        }

        final starsRaw = data['levelStars'];
        if (starsRaw is Map) {
          levelStars = {
            for (final entry in starsRaw.entries)
              int.tryParse(entry.key.toString()) ?? 0: (entry.value as num).toInt(),
          };
          levelStars.remove(0);
        }

        final boardsRaw = data['unlockedBoards'];
        if (boardsRaw is List) {
          unlockedBoards = boardsRaw.map((e) => e.toString()).toSet();
        }

        final seedsRaw = data['unlockedSeeds'];
        if (seedsRaw is List) {
          unlockedSeeds = seedsRaw.map((e) => e.toString()).toSet();
        }

        final aiRaw = data['unlockedAiTiers'];
        if (aiRaw is List) {
          unlockedAiTiers = aiRaw.map((e) => e.toString()).toSet();
        }

        final heat5Raw = data['heatMap5'];
        if (heat5Raw is List && heat5Raw.length == 25) {
          heatMap5 = heat5Raw.map((e) => (e as num).toInt()).toList();
        }

        final heat6Raw = data['heatMap6'];
        if (heat6Raw is List && heat6Raw.length == 36) {
          heatMap6 = heat6Raw.map((e) => (e as num).toInt()).toList();
        }
      } catch (_) {
        // ignore corrupted profile
      }
    }

    _ensureDefaults();
  }

  Future<void> save() async {
    final data = {
      'coins': coins,
      'highestUnlockedLevel': highestUnlockedLevel,
      'levelStars': levelStars.map((k, v) => MapEntry(k.toString(), v)),
      'unlockedBoards': unlockedBoards.toList(),
      'unlockedSeeds': unlockedSeeds.toList(),
      'unlockedAiTiers': unlockedAiTiers.toList(),
      'equippedBoard': equippedBoard,
      'equippedSeed': equippedSeed,
      'lastDailyReward': lastDailyReward?.toIso8601String(),
      'extraHints': extraHints,
      'extraUndos': extraUndos,
      'games': games,
      'wins': wins,
      'playerAggression': playerAggression,
      'heatMap5': heatMap5,
      'heatMap6': heatMap6,
    };
    await _prefs.setString('profile', jsonEncode(data));
  }

  void _ensureDefaults() {
    if (highestUnlockedLevel < 1) highestUnlockedLevel = 1;
    if (coins < 0) coins = 0;

    unlockedBoards.add('wood_classic');
    unlockedSeeds.add('stone_classic');

    unlockedAiTiers.addAll(['beginner', 'amateur', 'pro', 'master']);

    if (!unlockedBoards.contains(equippedBoard)) {
      equippedBoard = 'wood_classic';
    }
    if (!unlockedSeeds.contains(equippedSeed)) {
      equippedSeed = 'stone_classic';
    }

    if (heatMap5.length != 25) heatMap5 = List<int>.filled(25, 0);
    if (heatMap6.length != 36) heatMap6 = List<int>.filled(36, 0);
  }

  bool isLevelUnlocked(int levelId) => levelId <= highestUnlockedLevel;

  int starsFor(int levelId) => levelStars[levelId] ?? 0;

  void setStars(int levelId, int stars) {
    final current = levelStars[levelId] ?? 0;
    if (stars > current) {
      levelStars[levelId] = stars;
    }
  }

  void unlockNextLevel(int completedLevel) {
    final next = completedLevel + 1;
    if (next > highestUnlockedLevel) {
      highestUnlockedLevel = next;
    }
  }

  void addCoins(int amount) {
    coins += amount;
    if (coins < 0) coins = 0;
  }

  bool spendCoins(int amount) {
    if (coins < amount) return false;
    coins -= amount;
    return true;
  }

  bool canClaimDaily() {
    if (lastDailyReward == null) return true;
    final diff = DateTime.now().difference(lastDailyReward!);
    return diff.inHours >= 20;
  }

  int claimDaily() {
    if (!canClaimDaily()) return 0;
    const reward = 120;
    coins += reward;
    lastDailyReward = DateTime.now();
    return reward;
  }

  void recordGame({required bool playerWon, required int playerCaptures, required int totalMoves}) {
    games += 1;
    if (playerWon) wins += 1;

    final captureRate = totalMoves == 0 ? 0.0 : playerCaptures / totalMoves;
    playerAggression = (playerAggression * 0.8) + (captureRate * 0.2);
    if (playerAggression < 0) playerAggression = 0;
    if (playerAggression > 1) playerAggression = 1;
  }

  List<int> heatForSize(int size) {
    return size == 5 ? heatMap5 : heatMap6;
  }

  void recordPlacement({required int idx, required int size}) {
    final heat = size == 5 ? heatMap5 : heatMap6;
    if (idx < 0 || idx >= heat.length) return;
    heat[idx] = heat[idx] + 1;
  }
}
