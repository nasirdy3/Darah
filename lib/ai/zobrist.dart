import 'dart:math';

import '../game/state.dart';
import '../game/types.dart';

class Zobrist {
  Zobrist(int size)
      : _size = size,
        _rand = Random(1987),
        _boardKeys = List.generate(36, (_) => List<int>.filled(2, 0)),
        _turnKeys = List<int>.filled(2, 0),
        _phaseKeys = List<int>.filled(3, 0),
        _captureKeys = List<int>.filled(2, 0),
        _sizeKeys = List<int>.filled(2, 0) {
    for (var i = 0; i < 36; i++) {
      _boardKeys[i][0] = _next64();
      _boardKeys[i][1] = _next64();
    }
    _turnKeys[0] = _next64();
    _turnKeys[1] = _next64();
    _phaseKeys[0] = _next64();
    _phaseKeys[1] = _next64();
    _phaseKeys[2] = _next64();
    _captureKeys[0] = _next64();
    _captureKeys[1] = _next64();
    _sizeKeys[0] = _next64();
    _sizeKeys[1] = _next64();
  }

  final int _size;
  final Random _rand;
  final List<List<int>> _boardKeys;
  final List<int> _turnKeys;
  final List<int> _phaseKeys;
  final List<int> _captureKeys;
  final List<int> _sizeKeys;

  int hash(GameState gs) {
    int h = 0;
    final n = gs.cfg.size;
    final cells = n * n;

    for (var idx = 0; idx < cells; idx++) {
      final p = gs.board[idx];
      if (p == Player.none) continue;
      final pIdx = p == Player.p1 ? 0 : 1;
      h ^= _boardKeys[idx][pIdx];
    }

    h ^= _turnKeys[gs.turn == Player.p1 ? 0 : 1];
    h ^= _phaseKeys[gs.phase.index];

    if (gs.captureBy != Player.none) {
      h ^= _captureKeys[gs.captureBy == Player.p1 ? 0 : 1];
    }

    h ^= _sizeKeys[_size == 5 ? 0 : 1];

    return h;
  }

  int _next64() {
    final hi = _rand.nextInt(1 << 32);
    final lo = _rand.nextInt(1 << 32);
    return (hi << 32) ^ lo;
  }
}
