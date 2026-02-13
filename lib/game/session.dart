import 'config.dart';
import 'state.dart';
import 'types.dart';

class GameSession {
  GameSession({required this.cfg, required this.human}) : gs = GameState(cfg);

  final BoardConfig cfg;
  final Player human;

  GameState gs;

  int totalMoves = 0;
  int humanCaptures = 0;
  int aiCaptures = 0;

  final List<_Snapshot> _history = [];

  void reset() {
    gs = GameState(cfg);
    totalMoves = 0;
    humanCaptures = 0;
    aiCaptures = 0;
    _history.clear();
  }

  void pushSnapshot() {
    _history.add(_Snapshot(gs.clone(), totalMoves, humanCaptures, aiCaptures));
  }

  bool get canUndo => _history.isNotEmpty;

  void undo() {
    if (_history.isEmpty) return;
    final snap = _history.removeLast();
    gs = snap.gs;
    totalMoves = snap.totalMoves;
    humanCaptures = snap.humanCaptures;
    aiCaptures = snap.aiCaptures;
  }

  void recordMove(Move mv, {required Player by}) {
    totalMoves += 1;
    if (mv.kind == MoveKind.capture) {
      if (by == human) {
        humanCaptures += 1;
      } else {
        aiCaptures += 1;
      }
    }
  }
}

class _Snapshot {
  _Snapshot(this.gs, this.totalMoves, this.humanCaptures, this.aiCaptures);

  final GameState gs;
  final int totalMoves;
  final int humanCaptures;
  final int aiCaptures;
}
