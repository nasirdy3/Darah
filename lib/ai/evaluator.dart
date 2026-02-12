import '../game/dara_detector.dart';
import '../game/state.dart';
import '../game/types.dart';

class Evaluator {
  static int evaluate(GameState gs, Player me) {
    final opp = me.opponent;

    final seedScore = (me == Player.p1 ? gs.remainingP1 : gs.remainingP2) -
        (opp == Player.p1 ? gs.remainingP1 : gs.remainingP2);

    // potential and current dara
    final myDara = DaraDetector.countExact3(gs, me);
    final oppDara = DaraDetector.countExact3(gs, opp);

    // mobility
    final myMob = _mobility(gs, me);
    final oppMob = _mobility(gs, opp);

    return seedScore * 120 + myDara * 60 - oppDara * 70 + (myMob - oppMob) * 8;
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
}
