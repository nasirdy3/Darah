import 'rules.dart';
import 'state.dart';
import 'types.dart';

class MoveGenerator {
  static List<Move> generate(GameState gs) {
    final n = gs.cfg.size;
    final moves = <Move>[];

    if (gs.phase == Phase.placement) {
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          if (Rules.isLegalPlace(gs, r, c)) {
            moves.add(Move.place(r, c));
          }
        }
      }
      return moves;
    }

    if (gs.phase == Phase.capture) {
      final enemy = gs.captureBy.opponent;
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          if (gs.getCell(r, c) == enemy) {
            moves.add(Move.capture(r, c));
          }
        }
      }
      return moves;
    }

    // Movement
    const dirs = [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
    ];

    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (gs.getCell(r, c) != gs.turn) continue;
        for (final d in dirs) {
          final tr = r + d[0];
          final tc = c + d[1];
          if (!gs.cfg.inBounds(tr, tc)) continue;
          if (Rules.isLegalStep(gs, r, c, tr, tc)) {
            moves.add(Move.step(r, c, tr, tc));
          }
        }
      }
    }

    return moves;
  }
}
