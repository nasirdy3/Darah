enum Player { none, p1, p2 }

enum Phase { placement, movement, capture }

extension PlayerX on Player {
  Player get opponent => this == Player.p1 ? Player.p2 : Player.p1;
}

class Move {
  const Move.place(this.r, this.c)
      : kind = MoveKind.place,
        fr = null,
        fc = null,
        tr = null,
        tc = null,
        capR = null,
        capC = null;

  const Move.step(this.fr, this.fc, this.tr, this.tc)
      : kind = MoveKind.step,
        r = null,
        c = null,
        capR = null,
        capC = null;

  const Move.capture(this.capR, this.capC)
      : kind = MoveKind.capture,
        r = null,
        c = null,
        fr = null,
        fc = null,
        tr = null,
        tc = null;

  final MoveKind kind;
  final int? r;
  final int? c;
  final int? fr;
  final int? fc;
  final int? tr;
  final int? tc;
  final int? capR;
  final int? capC;
}

enum MoveKind { place, step, capture }
