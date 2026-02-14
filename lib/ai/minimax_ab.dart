import 'dart:math';

import '../game/move_generator.dart';
import '../game/rules.dart';
import '../game/state.dart';
import '../game/types.dart';
import 'ai_config.dart';
import 'evaluator.dart';
import 'transposition.dart';
import 'zobrist.dart';

class MinimaxAB {
  static ({Move? best, int score, bool timeout}) search({
    required GameState gs,
    required Player me,
    required int depth,
    required int timeLimitMs,
    required int startMs,
    required AiSearchConfig config,
    required Zobrist zobrist,
    required TranspositionTable tt,
    required Random rng,
    List<int>? heatMap,
  }) {
    final endAt = startMs + timeLimitMs;

    int now() => DateTime.now().millisecondsSinceEpoch;

    bool isTimeout() => now() >= endAt;

    final killerMoves = <int, Move>{};
    final history = <int, int>{};

    int moveKey(Move mv) {
      switch (mv.kind) {
        case MoveKind.place:
          return (mv.r! * 31) ^ (mv.c! * 17) ^ 11;
        case MoveKind.step:
          return (mv.fr! * 31) ^ (mv.fc! * 17) ^ (mv.tr! * 13) ^ (mv.tc! * 7) ^ 23;
        case MoveKind.capture:
          return (mv.capR! * 29) ^ (mv.capC! * 19) ^ 31;
      }
    }

    int alphabeta(GameState state, int d, int alpha, int beta, bool maximizing) {
      if (isTimeout()) return 0;
      final winner = Rules.winner(state);
      if (winner != Player.none) {
        return winner == me ? 1000000 : -1000000;
      }
      if (d == 0) {
        return Evaluator.evaluate(state, me,
            aggressionBias: config.adaptiveBias, playerHeat: heatMap);
      }

      final key = zobrist.hash(state);
      final entry = tt.get(key);
      if (entry != null && entry.depth >= d) {
        if (entry.flag == 0) return entry.score;
        if (entry.flag < 0) {
          beta = min(beta, entry.score);
        } else if (entry.flag > 0) {
          alpha = max(alpha, entry.score);
        }
        if (alpha >= beta) return entry.score;
      }

      final moves = MoveGenerator.generate(state);
      if (moves.isEmpty) {
        return maximizing ? -999999 : 999999;
      }

      final killer = killerMoves[d];
      _orderMoves(moves, state, me, entry?.best, killer, history, config.adaptiveBias, heatMap);

      final alphaOrig = alpha;
      final betaOrig = beta;

      int value;
      Move? best;
      if (maximizing) {
        value = -9999999;
        for (final mv in moves) {
          if (isTimeout()) break;
          final child = _applyClone(state, mv);
          final score = alphabeta(child, d - 1, alpha, beta, false);
          if (score > value) {
            value = score;
            best = mv;
          }
          alpha = max(alpha, value);
          if (alpha >= beta) {
            killerMoves[d] = mv;
            final key = moveKey(mv);
            history[key] = (history[key] ?? 0) + d * d;
            break;
          }
        }
      } else {
        value = 9999999;
        for (final mv in moves) {
          if (isTimeout()) break;
          final child = _applyClone(state, mv);
          final score = alphabeta(child, d - 1, alpha, beta, true);
          if (score < value) {
            value = score;
            best = mv;
          }
          beta = min(beta, value);
          if (beta <= alpha) {
            killerMoves[d] = mv;
            final key = moveKey(mv);
            history[key] = (history[key] ?? 0) + d * d;
            break;
          }
        }
      }

      int flag = 0;
      if (value <= alphaOrig) flag = -1;
      if (value >= betaOrig) flag = 1;

      tt.put(
        key,
        TranspositionEntry(depth: d, score: value, flag: flag, best: best, age: tt.age),
      );

      return value;
    }

    Move? best;
    var bestScore = -9999999;

    tt.tick();
    tt.prune(maxAge: 4);
    final rootMoves = MoveGenerator.generate(gs);
    if (rootMoves.isEmpty) {
      return (best: null, score: -9999999, timeout: false);
    }

    _orderMoves(
      rootMoves,
      gs,
      me,
      tt.get(zobrist.hash(gs))?.best,
      null,
      history,
      config.adaptiveBias,
      heatMap,
    );

    final scored = <_MoveScore>[];
    for (final mv in rootMoves) {
      if (isTimeout()) break;
      final child = _applyClone(gs, mv);
      final score = alphabeta(child, depth - 1, -9999999, 9999999, false);
      if (isTimeout()) break;
      scored.add(_MoveScore(mv, score));
      if (score > bestScore) {
        bestScore = score;
        best = mv;
      }
    }

    if (config.randomness > 0 && scored.isNotEmpty) {
      scored.sort((a, b) => b.score.compareTo(a.score));
      final bestLocal = scored.first.score;
      final threshold = (120 * config.randomness).round();
      final pool = scored.where((s) => (bestLocal - s.score) <= threshold).toList();
      if (pool.length > 1) {
        best = pool[rng.nextInt(pool.length)].move;
      }
    }

    return (best: best, score: bestScore, timeout: isTimeout());
  }

  static void _orderMoves(
    List<Move> moves,
    GameState state,
    Player me,
    Move? best,
    Move? killer,
    Map<int, int> history,
    double aggressionBias,
    List<int>? heatMap,
  ) {
    if (best != null) {
      for (var i = 0; i < moves.length; i++) {
        if (_sameMove(moves[i], best)) {
          final mv = moves.removeAt(i);
          moves.insert(0, mv);
          break;
        }
      }
    }

    if (killer != null) {
      for (var i = 0; i < moves.length; i++) {
        if (_sameMove(moves[i], killer)) {
          final mv = moves.removeAt(i);
          moves.insert(0, mv);
          break;
        }
      }
    }

    int keyFor(Move mv) {
      switch (mv.kind) {
        case MoveKind.place:
          return (mv.r! * 31) ^ (mv.c! * 17) ^ 11;
        case MoveKind.step:
          return (mv.fr! * 31) ^ (mv.fc! * 17) ^ (mv.tr! * 13) ^ (mv.tc! * 7) ^ 23;
        case MoveKind.capture:
          return (mv.capR! * 29) ^ (mv.capC! * 19) ^ 31;
      }
    }

    moves.sort((a, b) {
      final sa = Evaluator.evaluate(_applyClone(state, a), me,
              aggressionBias: aggressionBias, playerHeat: heatMap) +
          (history[keyFor(a)] ?? 0);
      final sb = Evaluator.evaluate(_applyClone(state, b), me,
              aggressionBias: aggressionBias, playerHeat: heatMap) +
          (history[keyFor(b)] ?? 0);
      return sb.compareTo(sa);
    });
  }

  static bool _sameMove(Move a, Move b) {
    if (a.kind != b.kind) return false;
    switch (a.kind) {
      case MoveKind.place:
        return a.r == b.r && a.c == b.c;
      case MoveKind.step:
        return a.fr == b.fr && a.fc == b.fc && a.tr == b.tr && a.tc == b.tc;
      case MoveKind.capture:
        return a.capR == b.capR && a.capC == b.capC;
    }
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

class _MoveScore {
  const _MoveScore(this.move, this.score);
  final Move move;
  final int score;
}
