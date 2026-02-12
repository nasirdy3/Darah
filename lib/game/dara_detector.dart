import 'state.dart';
import 'types.dart';

class DaraDetector {
  static int countExact3(GameState gs, Player p) {
    final n = gs.cfg.size;
    var count = 0;

    // Horizontal
    for (var r = 0; r < n; r++) {
      var run = 0;
      for (var c = 0; c < n; c++) {
        if (gs.getCell(r, c) == p) {
          run++;
        } else {
          if (run == 3) count++;
          run = 0;
        }
      }
      if (run == 3) count++;
    }

    // Vertical
    for (var c = 0; c < n; c++) {
      var run = 0;
      for (var r = 0; r < n; r++) {
        if (gs.getCell(r, c) == p) {
          run++;
        } else {
          if (run == 3) count++;
          run = 0;
        }
      }
      if (run == 3) count++;
    }

    return count;
  }

  static bool has4Plus(GameState gs, Player p) {
    final n = gs.cfg.size;

    for (var r = 0; r < n; r++) {
      var run = 0;
      for (var c = 0; c < n; c++) {
        if (gs.getCell(r, c) == p) {
          run++;
          if (run >= 4) return true;
        } else {
          run = 0;
        }
      }
    }

    for (var c = 0; c < n; c++) {
      var run = 0;
      for (var r = 0; r < n; r++) {
        if (gs.getCell(r, c) == p) {
          run++;
          if (run >= 4) return true;
        } else {
          run = 0;
        }
      }
    }

    return false;
  }
}
