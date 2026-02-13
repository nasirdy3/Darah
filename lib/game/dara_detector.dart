import 'state.dart';
import 'types.dart';

class DaraLine {
  const DaraLine(this.r, this.c, this.dr, this.dc);

  final int r;
  final int c;
  final int dr;
  final int dc;

  @override
  bool operator ==(Object other) {
    return other is DaraLine && r == other.r && c == other.c && dr == other.dr && dc == other.dc;
  }

  @override
  int get hashCode => Object.hash(r, c, dr, dc);

  @override
  String toString() => '($r,$c,$dr,$dc)';
}

class DaraDetector {
  static bool has3Plus(GameState gs, Player p) {
    final n = gs.cfg.size;

    for (var r = 0; r < n; r++) {
      var run = 0;
      for (var c = 0; c < n; c++) {
        if (gs.getCell(r, c) == p) {
          run++;
          if (run >= 3) return true;
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
          if (run >= 3) return true;
        } else {
          run = 0;
        }
      }
    }

    return false;
  }

  static int countExact3(GameState gs, Player p) {
    return exact3Lines(gs, p).length;
  }

  static Set<DaraLine> exact3Lines(GameState gs, Player p) {
    final n = gs.cfg.size;
    final set = <DaraLine>{};

    // Horizontal
    for (var r = 0; r < n; r++) {
      var run = 0;
      for (var c = 0; c < n; c++) {
        if (gs.getCell(r, c) == p) {
          run++;
        } else {
          if (run == 3) {
            set.add(DaraLine(r, c - 3, 0, 1));
          }
          run = 0;
        }
      }
      if (run == 3) {
        set.add(DaraLine(r, n - 3, 0, 1));
      }
    }

    // Vertical
    for (var c = 0; c < n; c++) {
      var run = 0;
      for (var r = 0; r < n; r++) {
        if (gs.getCell(r, c) == p) {
          run++;
        } else {
          if (run == 3) {
            set.add(DaraLine(r - 3, c, 1, 0));
          }
          run = 0;
        }
      }
      if (run == 3) {
        set.add(DaraLine(n - 3, c, 1, 0));
      }
    }

    return set;
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
