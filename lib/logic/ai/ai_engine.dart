import '../engine.dart';
import '../models.dart';
import 'dart:math';

enum Winner { black, white, none }

class Move {
  final Point from;
  final Point to;
  Move(this.from, this.to);
}

class DaraAI {
  final DaraEngine engine;
  final int depth;
  final Random _rng = Random();

  DaraAI(this.engine, this.depth);

  // === PLACEMENT PHASE ===
  Point? getBestPlacement() {
    List<Point> available = [];
    for (int y = 0; y < engine.gridSize; y++) {
      for (int x = 0; x < engine.gridSize; x++) {
        if (engine.board[y][x] == PlayerColor.none &&
            !engine.wouldFormDara(x, y, engine.currentPlayer)) {
          available.add(Point(x, y));
        }
      }
    }
    if (available.isEmpty) return null;

    // Score positions: prefer positions that block opponent 2-in-a-rows
    // and those that build toward our own potential Daras
    available.sort((a, b) => _scorePlacement(b).compareTo(_scorePlacement(a)));
    // Add tiny jitter so AI isn't perfectly deterministic
    available.take(3).toList()..shuffle(_rng);
    return available.first;
  }

  double _scorePlacement(Point p) {
    double score = 0;
    PlayerColor me = engine.currentPlayer;
    PlayerColor opp = me == PlayerColor.black ? PlayerColor.white : PlayerColor.black;

    // Reward building 2-in-a-row (potential for Dara on future turn)
    engine.board[p.y][p.x] = me;
    if (engine.checkLine(p.x, p.y, 1, 0, me) == 2) score += 5;
    if (engine.checkLine(p.x, p.y, 0, 1, me) == 2) score += 5;
    engine.board[p.y][p.x] = PlayerColor.none;

    // Reward blocking opponent's 2-in-a-rows
    engine.board[p.y][p.x] = opp;
    if (engine.checkLine(p.x, p.y, 1, 0, opp) == 2) score += 4;
    if (engine.checkLine(p.x, p.y, 0, 1, opp) == 2) score += 4;
    engine.board[p.y][p.x] = PlayerColor.none;

    // Slightly prefer center
    double cx = engine.gridSize / 2.0;
    double dist = (p.x - cx).abs() + (p.y - cx).abs();
    score += (engine.gridSize - dist) * 0.3;

    return score + _rng.nextDouble() * 0.5;
  }

  // === CAPTURE PHASE ===
  Point? getBestCapture() {
    PlayerColor opp = engine.currentPlayer == PlayerColor.black ? PlayerColor.white : PlayerColor.black;
    List<Point> options = [];
    for (int y = 0; y < engine.gridSize; y++) {
      for (int x = 0; x < engine.gridSize; x++) {
        if (engine.board[y][x] == opp) options.add(Point(x, y));
      }
    }
    if (options.isEmpty) return null;
    options.sort((a, b) => _scoreCapture(b, opp).compareTo(_scoreCapture(a, opp)));
    return options.first;
  }

  double _scoreCapture(Point p, PlayerColor opp) {
    double score = 0;
    // Prefer capturing pieces that are part of 2-in-a-row threat
    if (engine.checkLine(p.x, p.y, 1, 0, opp) == 2) score += 10;
    if (engine.checkLine(p.x, p.y, 0, 1, opp) == 2) score += 10;
    // Prefer capturing isolated pieces (easier to trap)
    int neighbors = _countNeighbors(p, opp);
    score += (4 - neighbors) * 2;
    return score + _rng.nextDouble();
  }

  int _countNeighbors(Point p, PlayerColor color) {
    int count = 0;
    for (var adj in [Point(p.x+1,p.y),Point(p.x-1,p.y),Point(p.x,p.y+1),Point(p.x,p.y-1)]) {
      if (adj.x >= 0 && adj.x < engine.gridSize && adj.y >= 0 && adj.y < engine.gridSize) {
        if (engine.board[adj.y][adj.x] == color) count++;
      }
    }
    return count;
  }

  // === MOVEMENT PHASE ===
  Move? getBestMove() {
    List<Move> moves = _getAllLegalMoves(engine.currentPlayer);
    if (moves.isEmpty) return null;

    // For shallow depths just pick the best without full minimax
    if (depth <= 1) {
      moves.sort((a, b) => _quickScore(b, engine.currentPlayer).compareTo(_quickScore(a, engine.currentPlayer)));
      return moves.first;
    }

    double bestScore = double.negativeInfinity;
    Move? bestMove;
    for (var move in moves) {
      _applyMove(move, engine.currentPlayer);
      double score = _minimax(depth - 1, double.negativeInfinity, double.infinity, false);
      _undoMove(move, engine.currentPlayer);
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }
    return bestMove;
  }

  double _quickScore(Move move, PlayerColor color) {
    _applyMove(move, color);
    double s = _evaluateBoard(color);
    _undoMove(move, color);
    return s;
  }

  double _minimax(int d, double alpha, double beta, bool isMaximizing) {
    PlayerColor win = engine.checkWinner();
    if (win != PlayerColor.none) {
      if (win == engine.currentPlayer) return 1000.0 + d;
      return -1000.0 - d;
    }
    if (d == 0) return _evaluateBoard(engine.currentPlayer);

    PlayerColor maxColor = engine.currentPlayer;
    PlayerColor minColor = maxColor == PlayerColor.black ? PlayerColor.white : PlayerColor.black;

    if (isMaximizing) {
      double maxEval = double.negativeInfinity;
      for (var move in _getAllLegalMoves(maxColor)) {
        _applyMove(move, maxColor);
        double eval = _minimax(d - 1, alpha, beta, false);
        _undoMove(move, maxColor);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      double minEval = double.infinity;
      for (var move in _getAllLegalMoves(minColor)) {
        _applyMove(move, minColor);
        double eval = _minimax(d - 1, alpha, beta, true);
        _undoMove(move, minColor);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  double _evaluateBoard(PlayerColor me) {
    PlayerColor opp = me == PlayerColor.black ? PlayerColor.white : PlayerColor.black;

    int mySeeds = me == PlayerColor.black ? engine.blackSeedsRemaining : engine.whiteSeedsRemaining;
    int oppSeeds = me == PlayerColor.black ? engine.whiteSeedsRemaining : engine.blackSeedsRemaining;
    double score = (mySeeds - oppSeeds) * 20.0;

    // Board mobility
    score += _getAllLegalMoves(me).length * 1.5;
    score -= _getAllLegalMoves(opp).length * 1.5;

    // Reward 2-in-a-rows (one move from a Dara)
    for (int y = 0; y < engine.gridSize; y++) {
      for (int x = 0; x < engine.gridSize; x++) {
        if (engine.board[y][x] == me) {
          if (engine.checkLine(x, y, 1, 0, me) == 2) score += 3;
          if (engine.checkLine(x, y, 0, 1, me) == 2) score += 3;
        } else if (engine.board[y][x] == opp) {
          if (engine.checkLine(x, y, 1, 0, opp) == 2) score -= 4; // penalise opp threats
          if (engine.checkLine(x, y, 0, 1, opp) == 2) score -= 4;
        }
      }
    }
    return score;
  }

  List<Move> _getAllLegalMoves(PlayerColor color) {
    List<Move> moves = [];
    for (int y = 0; y < engine.gridSize; y++) {
      for (int x = 0; x < engine.gridSize; x++) {
        if (engine.board[y][x] == color) {
          Point from = Point(x, y);
          for (var to in [Point(x+1,y), Point(x-1,y), Point(x,y+1), Point(x,y-1)]) {
            if (to.x >= 0 && to.x < engine.gridSize && to.y >= 0 && to.y < engine.gridSize) {
              if (engine.board[to.y][to.x] == PlayerColor.none &&
                  !engine.wouldFormMoreThanThree(from, to, color)) {
                moves.add(Move(from, to));
              }
            }
          }
        }
      }
    }
    return moves;
  }

  void _applyMove(Move move, PlayerColor color) {
    engine.board[move.from.y][move.from.x] = PlayerColor.none;
    engine.board[move.to.y][move.to.x] = color;
  }

  void _undoMove(Move move, PlayerColor color) {
    engine.board[move.to.y][move.to.x] = PlayerColor.none;
    engine.board[move.from.y][move.from.x] = color;
  }
}
