import 'dara_detector.dart';
import 'state.dart';
import 'types.dart';

class Rules {
  static bool isLegalPlace(GameState gs, int r, int c) {
    if (gs.phase != Phase.placement) return false;
    if (!gs.cfg.inBounds(r, c)) return false;
    if (gs.getCell(r, c) != Player.none) return false;

    // simulate
    gs.setCell(r, c, gs.turn);
    final illegal = DaraDetector.has3Plus(gs, gs.turn);
    gs.setCell(r, c, Player.none);

    return !illegal;
  }

  static void applyPlace(GameState gs, int r, int c) {
    gs.setCell(r, c, gs.turn);
    if (gs.turn == Player.p1) {
      gs.placedP1++;
    } else {
      gs.placedP2++;
    }
    if (gs.allPlaced()) {
      gs.phase = Phase.movement;
    }
    gs.turn = gs.turn.opponent;
  }

  static bool isLegalStep(GameState gs, int fr, int fc, int tr, int tc) {
    if (gs.phase != Phase.movement) return false;
    if (!gs.cfg.inBounds(fr, fc) || !gs.cfg.inBounds(tr, tc)) return false;
    if (gs.getCell(fr, fc) != gs.turn) return false;
    if (gs.getCell(tr, tc) != Player.none) return false;

    final dr = (tr - fr).abs();
    final dc = (tc - fc).abs();
    if (dr + dc != 1) return false;

    // simulate
    gs.setCell(fr, fc, Player.none);
    gs.setCell(tr, tc, gs.turn);
    final illegal4 = DaraDetector.has4Plus(gs, gs.turn);
    final lineCount = DaraDetector.countExact3(gs, gs.turn);
    gs.setCell(tr, tc, Player.none);
    gs.setCell(fr, fc, gs.turn);

    if (illegal4) return false;
    if (lineCount > 1) return false; // cannot stack multiple Daras in one move

    return true;
  }

  static void applyStep(GameState gs, int fr, int fc, int tr, int tc) {
    final before = DaraDetector.exact3Lines(gs, gs.turn);

    gs.setCell(fr, fc, Player.none);
    gs.setCell(tr, tc, gs.turn);

    final after = DaraDetector.exact3Lines(gs, gs.turn);
    final newLines = after.difference(before);

    if (newLines.isNotEmpty) {
      gs.phase = Phase.capture;
      gs.captureBy = gs.turn;
    } else {
      gs.turn = gs.turn.opponent;
    }
  }

  static bool isLegalCapture(GameState gs, int r, int c) {
    if (gs.phase != Phase.capture) return false;
    if (!gs.cfg.inBounds(r, c)) return false;
    final enemy = gs.captureBy.opponent;
    return gs.getCell(r, c) == enemy;
  }

  static void applyCapture(GameState gs, int r, int c) {
    final enemy = gs.captureBy.opponent;
    gs.setCell(r, c, Player.none);

    if (enemy == Player.p1) {
      gs.remainingP1--;
    } else {
      gs.remainingP2--;
    }

    gs.phase = Phase.movement;
    gs.turn = enemy; // after capture, turn passes to captured player's side
    gs.captureBy = Player.none;
  }

  static bool isWin(GameState gs) {
    // A player loses if seeds < 3 OR no legal moves
    final p1Lose = gs.remainingP1 < 3 || (gs.phase == Phase.movement && gs.turn == Player.p1 && _noMoves(gs));
    final p2Lose = gs.remainingP2 < 3 || (gs.phase == Phase.movement && gs.turn == Player.p2 && _noMoves(gs));
    return p1Lose || p2Lose;
  }

  static Player winner(GameState gs) {
    final p1No = gs.remainingP1 < 3;
    final p2No = gs.remainingP2 < 3;
    if (p1No) return Player.p2;
    if (p2No) return Player.p1;

    if (gs.phase == Phase.movement) {
      if (gs.turn == Player.p1 && _noMoves(gs)) return Player.p2;
      if (gs.turn == Player.p2 && _noMoves(gs)) return Player.p1;
    }
    return Player.none;
  }

  static bool _noMoves(GameState gs) {
    final n = gs.cfg.size;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (gs.getCell(r, c) != gs.turn) continue;
        const dirs = [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
        ];
        for (final d in dirs) {
          final tr = r + d[0];
          final tc = c + d[1];
          if (!gs.cfg.inBounds(tr, tc)) continue;
          if (gs.getCell(tr, tc) == Player.none) return false;
        }
      }
    }
    return true;
  }
}
