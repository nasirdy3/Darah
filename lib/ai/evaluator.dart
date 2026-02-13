import '../game/dara_detector.dart';
import '../game/state.dart';
import '../game/types.dart';

class Evaluator {
  static int evaluate(GameState gs, Player me, {double aggressionBias = 0.5, List<int>? playerHeat}) {
    final opp = me.opponent;

    final seedScore = (me == Player.p1 ? gs.remainingP1 : gs.remainingP2) -
        (opp == Player.p1 ? gs.remainingP1 : gs.remainingP2);

    final myDara = DaraDetector.countExact3(gs, me);
    final oppDara = DaraDetector.countExact3(gs, opp);

    final myMob = _mobility(gs, me);
    final oppMob = _mobility(gs, opp);

    final myThreats = _threats(gs, me);
    final oppThreats = _threats(gs, opp);

    final centerScore = _centerScore(gs, me) - _centerScore(gs, opp);
    final preferenceScore = _preferenceScore(gs, me, playerHeat);

    final attackWeight = (0.8 + aggressionBias * 0.6).clamp(0.6, 1.6);
    final defenseWeight = (1.4 - aggressionBias * 0.6).clamp(0.6, 1.6);

    final phaseFactor = gs.phase == Phase.placement ? 0.7 : 1.0;

    final score =
        (seedScore * 140) +
        ((myDara - oppDara) * 85) +
        ((myMob - oppMob) * 10 * phaseFactor).round() +
        ((myThreats * 45 * attackWeight) - (oppThreats * 55 * defenseWeight)).round() +
        (centerScore * (gs.phase == Phase.placement ? 6 : 3)) +
        (preferenceScore * 6);

    return score;
  }

  static int _mobility(GameState gs, Player p) {
    final n = gs.cfg.size;
    var count = 0;
    const dirs = [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
    ];
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (gs.getCell(r, c) != p) continue;
        for (final d in dirs) {
          final tr = r + d[0];
          final tc = c + d[1];
          if (!gs.cfg.inBounds(tr, tc)) continue;
          if (gs.getCell(tr, tc) == Player.none) count++;
        }
      }
    }
    return count;
  }

  static int _threats(GameState gs, Player p) {
    final n = gs.cfg.size;
    var count = 0;

    for (var r = 0; r < n; r++) {
      for (var c = 0; c <= n - 3; c++) {
        var mine = 0;
        var opp = 0;
        for (var k = 0; k < 3; k++) {
          final cell = gs.getCell(r, c + k);
          if (cell == p) mine++;
          if (cell == p.opponent) opp++;
        }
        if (opp == 0 && mine == 2) count++;
      }
    }

    for (var c = 0; c < n; c++) {
      for (var r = 0; r <= n - 3; r++) {
        var mine = 0;
        var opp = 0;
        for (var k = 0; k < 3; k++) {
          final cell = gs.getCell(r + k, c);
          if (cell == p) mine++;
          if (cell == p.opponent) opp++;
        }
        if (opp == 0 && mine == 2) count++;
      }
    }

    return count;
  }

  static int _centerScore(GameState gs, Player p) {
    final n = gs.cfg.size;
    final center = (n - 1) / 2.0;
    final maxDist = (n - 1) + (n - 1);
    var score = 0.0;

    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (gs.getCell(r, c) != p) continue;
        final dist = (r - center).abs() + (c - center).abs();
        score += (maxDist - dist);
      }
    }

    return score.round();
  }

  static int _preferenceScore(GameState gs, Player me, List<int>? heat) {
    if (heat == null || heat.length != gs.cfg.size * gs.cfg.size) return 0;
    var maxHeat = 1;
    for (final v in heat) {
      if (v > maxHeat) maxHeat = v;
    }

    var myScore = 0;
    var oppScore = 0;
    for (var idx = 0; idx < heat.length; idx++) {
      final cell = gs.board[idx];
      if (cell == Player.none) continue;
      if (cell == me) {
        myScore += heat[idx];
      } else {
        oppScore += heat[idx];
      }
    }

    final diff = (myScore - oppScore) / maxHeat;
    return diff.round();
  }
}
