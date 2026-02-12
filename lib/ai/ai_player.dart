import 'dart:async';
import 'dart:isolate';

import '../game/state.dart';
import '../game/types.dart';
import 'minimax_ab.dart';

class AIPlayer {
  AIPlayer({required this.level});
  final int level;

  int _depthForLevel(int lvl, {required bool isPlacement}) {
    // Placement has bigger branching; keep shallower.
    if (isPlacement) {
      if (lvl <= 10) return 1;
      if (lvl <= 25) return 2;
      if (lvl <= 50) return 3;
      return 4;
    }
    if (lvl <= 10) return 2;
    if (lvl <= 20) return 3;
    if (lvl <= 35) return 4;
    if (lvl <= 55) return 5;
    if (lvl <= 80) return 6;
    return 7;
  }

  int _timeForLevel(int lvl) {
    // time budget in ms
    if (lvl <= 10) return 150;
    if (lvl <= 20) return 250;
    if (lvl <= 35) return 450;
    if (lvl <= 55) return 700;
    if (lvl <= 80) return 1000;
    return 1400;
  }

  Future<Move?> chooseMove(GameState gs, Player me) async {
    // Run in isolate to avoid UI jank
    final completer = Completer<Move?>();
    final rp = ReceivePort();
    final args = _IsolateArgs(gs, me, level);

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
    final depth = AIPlayer(level: args.level)._depthForLevel(args.level, isPlacement: args.gs.phase == Phase.placement);
    final timeMs = AIPlayer(level: args.level)._timeForLevel(args.level);

    // iterative deepening
    Move? best;
    for (var d = 1; d <= depth; d++) {
      final res = MinimaxAB.search(
        gs: args.gs,
        me: args.me,
        depth: d,
        timeLimitMs: timeMs,
        startMs: start,
      );
      if (res.best != null) best = res.best;
      if (res.timeout) break;
    }

    send.send(best);
  }
}

class _IsolateArgs {
  _IsolateArgs(this.gs, this.me, this.level);
  final GameState gs;
  final Player me;
  final int level;
}
