import 'dart:math';

import '../game/move_generator.dart';
import '../game/rules.dart';
import '../game/state.dart';
import '../game/types.dart';
import 'evaluator.dart';

class MinimaxAB {
  static ({Move? best, int score, bool timeout}) search({
    required GameState gs,
    required Player me,
    required int depth,
    required int timeLimitMs,
    required int startMs,
  }) {
    final endAt = startMs + timeLimitMs;

    int now() => DateTime.now().millisecondsSinceEpoch;

    bool isTimeout() => now() >= endAt;

    int alphabeta(GameState state, int d, int alpha, int beta, bool maximizing) {
      if (isTimeout()) return 0;
      final winner = Rules.winner(state);
      if (winner != Player.none) {
        return winner == me ? 1000000 : -1000000;
      }
      if (d == 0) {
        return Evaluator.evaluate(state, me);
      }

      final moves = MoveGenerator.generate(state);
      if (moves.isEmpty) {
        return maximizing ? -999999 : 999999;
      }

      if (maximizing) {
        var value = -9999999;
        for (final mv in moves) {
          if (isTimeout()) break;
          final child = _applyClone(state, mv);
          value = max(value, alphabeta(child, d - 1, alpha, beta, false));
          alpha = max(alpha, value);
          if (alpha >= beta) break;
        }
        return value;
      } else {
        var value = 9999999;
        for (final mv in moves) {
          if (isTimeout()) break;
          final child = _applyClone(state, mv);
          value = min(value, alphabeta(child, d - 1, alpha, beta, true));
          beta = min(beta, value);
          if (beta <= alpha) break;
        }
        return value;
      }
    }

    Move? best;
    var bestScore = -9999999;

    final rootMoves = MoveGenerator.generate(gs);
    if (rootMoves.isEmpty) {
      return (best: null, score: -9999999, timeout: false);
    }

    // Move ordering: quick eval
    final ordered = rootMoves.toList();
    ordered.sort((a, b) {
      final sa = Evaluator.evaluate(_applyClone(gs, a), me);
      final sb = Evaluator.evaluate(_applyClone(gs, b), me);
      return sb.compareTo(sa);
    });

    for (final mv in ordered) {
      if (isTimeout()) break;
      final child = _applyClone(gs, mv);
      final score = alphabeta(child, depth - 1, -9999999, 9999999, false);
      if (isTimeout()) break;
      if (score > bestScore) {
        bestScore = score;
        best = mv;
      }
    }

    return (best: best, score: bestScore, timeout: isTimeout());
  }

  static GameState _applyClone(GameState s, Move mv) {
    final gs = s.clone();
    switch (mv.kind) {
      case MoveKind.place:
        Rules.applyPlace(gs, mv.r!, mv.c!);
        return gs;
      case MoveKind.step:
        Rules.applyStep(gs, mv.fr!, mv.fc!, mv.tr!, mv.tc!);
        return gs;
      case MoveKind.capture:
        Rules.applyCapture(gs, mv.capR!, mv.capC!);
        return gs;
    }
  }
}
