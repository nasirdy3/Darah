import 'package:flutter/foundation.dart';
import 'engine.dart';
import 'models.dart';
import 'ai/ai_engine.dart';
import 'audio_manager.dart';

enum GameResult { playing, blackWins, whiteWins }

class GameState extends ChangeNotifier {
  DaraEngine engine;
  final bool isAiGame;
  final int difficultyDepth;
  DaraAI? ai;
  final VoidCallback? onWin;

  GameResult result = GameResult.playing;
  Point? selectedSeed;
  Set<String> capturableKeys = {};

  GameState({int gridSize = 5, this.isAiGame = true, this.difficultyDepth = 3, this.onWin})
      : engine = DaraEngine(gridSize: gridSize) {
    if (isAiGame) {
      ai = DaraAI(engine, difficultyDepth);
    }
  }

  bool get isGameOver => result != GameResult.playing;

  void handleTap(int x, int y) async {
    if (isGameOver) return;

    if (engine.currentPhase == GamePhase.placement) {
      if (engine.placeSeed(x, y)) {
        AudioManager.instance.playPlace();
        _postAction();
        if (isAiGame && !isGameOver && engine.currentPlayer == PlayerColor.white) {
          await Future.delayed(const Duration(milliseconds: 450));
          _aiTurn();
        }
      }
    } else if (engine.currentPhase == GamePhase.movement) {
      final tap = Point(x, y);
      if (engine.board[y][x] == engine.currentPlayer) {
        // Select or deselect
        selectedSeed = (selectedSeed == tap) ? null : tap;
        notifyListeners();
      } else if (selectedSeed != null && engine.board[y][x] == PlayerColor.none) {
        if (engine.moveSeed(selectedSeed!, tap)) {
          AudioManager.instance.playMove();
          selectedSeed = null;
          _postAction();
          if (engine.currentPhase == GamePhase.capturing) {
            // Update capturable highlights
            _updateCapturableKeys();
          } else if (isAiGame && !isGameOver && engine.currentPlayer == PlayerColor.white) {
            await Future.delayed(const Duration(milliseconds: 650));
            _aiTurn();
          }
        }
      } else {
        selectedSeed = null;
        notifyListeners();
      }
    } else if (engine.currentPhase == GamePhase.capturing) {
      if (engine.captureSeed(x, y)) {
        AudioManager.instance.playCapture();
        selectedSeed = null;
        capturableKeys.clear();
        _postAction();
        if (isAiGame && !isGameOver && engine.currentPlayer == PlayerColor.white) {
          await Future.delayed(const Duration(milliseconds: 700));
          _aiTurn();
        }
      }
    }
  }

  void _postAction() {
    final w = engine.checkWinner();
    if (w == PlayerColor.black) {
      result = GameResult.blackWins;
      AudioManager.instance.playWin();
      onWin?.call();
    }
    if (w == PlayerColor.white) {
      result = GameResult.whiteWins;
      AudioManager.instance.playWin();
    }
    notifyListeners();
  }

  void _updateCapturableKeys() {
    capturableKeys.clear();
    PlayerColor opp = engine.currentPlayer == PlayerColor.black
        ? PlayerColor.white
        : PlayerColor.black;
    for (int yy = 0; yy < engine.gridSize; yy++) {
      for (int xx = 0; xx < engine.gridSize; xx++) {
        if (engine.board[yy][xx] == opp) capturableKeys.add('$xx,$yy');
      }
    }
    notifyListeners();
  }

  void _aiTurn() {
    if (isGameOver) return;
    if (engine.currentPhase == GamePhase.placement) {
      final p = ai?.getBestPlacement();
      if (p != null) handleTap(p.x, p.y);
    } else if (engine.currentPhase == GamePhase.movement) {
      final m = ai?.getBestMove();
      if (m != null) {
        engine.moveSeed(m.from, m.to);
        selectedSeed = null;
        _postAction();
        if (engine.currentPhase == GamePhase.capturing) {
          _updateCapturableKeys();
          Future.delayed(const Duration(milliseconds: 600), () {
            final p = ai?.getBestCapture();
            if (p != null) handleTap(p.x, p.y);
          });
        }
      }
    } else if (engine.currentPhase == GamePhase.capturing) {
      final p = ai?.getBestCapture();
      if (p != null) handleTap(p.x, p.y);
    }
  }

  void reset() {
    engine = DaraEngine(gridSize: engine.gridSize);
    if (isAiGame) ai = DaraAI(engine, difficultyDepth);
    result = GameResult.playing;
    selectedSeed = null;
    capturableKeys.clear();
    notifyListeners();
  }

  List<List<int>> getValidMoveTargets() {
    if (selectedSeed == null || engine.currentPhase != GamePhase.movement) return [];
    final p = selectedSeed!;
    List<List<int>> targets = [];
    for (var adj in [
      [p.x + 1, p.y], [p.x - 1, p.y], [p.x, p.y + 1], [p.x, p.y - 1]
    ]) {
      final tx = adj[0], ty = adj[1];
      if (tx >= 0 && tx < engine.gridSize && ty >= 0 && ty < engine.gridSize) {
        if (engine.board[ty][tx] == PlayerColor.none &&
            !engine.wouldFormMoreThanThree(p, Point(tx, ty), engine.currentPlayer)) {
          targets.add([tx, ty]);
        }
      }
    }
    return targets;
  }
}
