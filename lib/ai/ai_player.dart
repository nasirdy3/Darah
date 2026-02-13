import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import '../game/state.dart';
import '../game/types.dart';
import 'ai_config.dart';
import 'minimax_ab.dart';
import 'transposition.dart';
import 'zobrist.dart';

class AIPlayer {
  AIPlayer({required this.profile});
  final AiProfile profile;

  Future<Move?> chooseMove(GameState gs, Player me) async {
    final completer = Completer<Move?>();
    final rp = ReceivePort();
    final args = _IsolateArgs(gs, me, profile);

    await Isolate.spawn(_isolateEntry, (rp.sendPort, args));

    rp.listen((msg) {
      if (msg is Move || msg == null) {
        completer.complete(msg as Move?);
        rp.close();
      }
    });

    return completer.future;
  }

  static void _isolateEntry(dynamic payload) {
    final send = payload.$1 as SendPort;
    final args = payload.$2 as _IsolateArgs;

    final start = DateTime.now().millisecondsSinceEpoch;
    final profile = AiProfile(
      tier: AiTierX.fromId(args.tierId),
      level: args.level,
      playerAggression: args.playerAggression,
      playerHeat: args.playerHeat,
      boardSize: args.boardSize,
    );
    final config = configFor(profile, isPlacement: args.gs.phase == Phase.placement);

    final zobrist = Zobrist(args.gs.cfg.size);
    final tt = TranspositionTable();
    final rng = Random(args.seed);

    Move? best;
    for (var d = 1; d <= config.depth; d++) {
      final res = MinimaxAB.search(
        gs: args.gs,
        me: args.me,
        depth: d,
        timeLimitMs: config.timeMs,
        startMs: start,
        config: config,
        zobrist: zobrist,
        tt: tt,
        rng: rng,
        heatMap: args.playerHeat,
      );
      if (res.best != null) best = res.best;
      if (res.timeout) break;
    }

    send.send(best);
  }
}

class _IsolateArgs {
  _IsolateArgs(this.gs, this.me, AiProfile profile)
      : level = profile.level,
        tierId = profile.tier.id,
        playerAggression = profile.playerAggression,
        playerHeat = profile.playerHeat,
        boardSize = profile.boardSize,
        seed = DateTime.now().microsecondsSinceEpoch;

  final GameState gs;
  final Player me;
  final int level;
  final String tierId;
  final double playerAggression;
  final List<int> playerHeat;
  final int boardSize;
  final int seed;
}
