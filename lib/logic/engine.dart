import 'models.dart';

class DaraEngine {
  final int gridSize;
  final int totalSeedsPerPlayer;

  List<List<PlayerColor>> board;
  PlayerColor currentPlayer = PlayerColor.black;
  GamePhase currentPhase = GamePhase.placement;

  int blackSeedsPlaced = 0;
  int whiteSeedsPlaced = 0;
  int blackSeedsRemaining;
  int whiteSeedsRemaining;

  DaraEngine({required this.gridSize})
      : totalSeedsPerPlayer = (gridSize == 5 ? 6 : 12),
        blackSeedsRemaining = (gridSize == 5 ? 6 : 12),
        whiteSeedsRemaining = (gridSize == 5 ? 6 : 12),
        board = List.generate(
            gridSize, (_) => List.filled(gridSize, PlayerColor.none));

  bool placeSeed(int x, int y) {
    if (currentPhase != GamePhase.placement) return false;
    if (board[y][x] != PlayerColor.none) return false;
    if (wouldFormDara(x, y, currentPlayer)) return false;

    board[y][x] = currentPlayer;
    if (currentPlayer == PlayerColor.black) {
      blackSeedsPlaced++;
    } else {
      whiteSeedsPlaced++;
    }

    _checkPhaseTransition();
    _switchPlayer();
    return true;
  }

  bool moveSeed(Point from, Point to) {
    if (currentPhase != GamePhase.movement) return false;
    if (board[from.y][from.x] != currentPlayer) return false;
    if (board[to.y][to.x] != PlayerColor.none) return false;

    int dx = (from.x - to.x).abs();
    int dy = (from.y - to.y).abs();
    if (!((dx == 1 && dy == 0) || (dx == 0 && dy == 1))) return false;

    if (wouldFormMoreThanThree(from, to, currentPlayer)) return false;

    board[from.y][from.x] = PlayerColor.none;
    board[to.y][to.x] = currentPlayer;

    if (isDaraFormed(to.x, to.y, currentPlayer)) {
      currentPhase = GamePhase.capturing;
    } else {
      _switchPlayer();
    }
    return true;
  }

  bool captureSeed(int x, int y) {
    if (currentPhase != GamePhase.capturing) return false;
    PlayerColor opponent =
        currentPlayer == PlayerColor.black ? PlayerColor.white : PlayerColor.black;
    if (board[y][x] != opponent) return false;

    board[y][x] = PlayerColor.none;
    if (opponent == PlayerColor.black) {
      blackSeedsRemaining--;
    } else {
      whiteSeedsRemaining--;
    }

    currentPhase = GamePhase.movement;
    _switchPlayer();
    return true;
  }

  void _switchPlayer() {
    currentPlayer =
        (currentPlayer == PlayerColor.black) ? PlayerColor.white : PlayerColor.black;
  }

  void _checkPhaseTransition() {
    if (blackSeedsPlaced == totalSeedsPerPlayer &&
        whiteSeedsPlaced == totalSeedsPerPlayer) {
      currentPhase = GamePhase.movement;
    }
  }

  bool wouldFormDara(int x, int y, PlayerColor color) {
    board[y][x] = color;
    bool forms = (checkLine(x, y, 1, 0, color) == 3 ||
        checkLine(x, y, 0, 1, color) == 3);
    board[y][x] = PlayerColor.none;
    return forms;
  }

  bool isDaraFormed(int x, int y, PlayerColor color) {
    return checkLine(x, y, 1, 0, color) == 3 || checkLine(x, y, 0, 1, color) == 3;
  }

  bool wouldFormMoreThanThree(Point from, Point to, PlayerColor color) {
    PlayerColor originalFrom = board[from.y][from.x];
    PlayerColor originalTo = board[to.y][to.x];
    board[from.y][from.x] = PlayerColor.none;
    board[to.y][to.x] = color;
    bool result = checkLine(to.x, to.y, 1, 0, color) > 3 ||
        checkLine(to.x, to.y, 0, 1, color) > 3;
    board[to.y][to.x] = originalTo;
    board[from.y][from.x] = originalFrom;
    return result;
  }

  int checkLine(int x, int y, int dx, int dy, PlayerColor color) {
    int count = 1;
    int tx = x + dx, ty = y + dy;
    while (tx >= 0 && tx < gridSize && ty >= 0 && ty < gridSize && board[ty][tx] == color) {
      count++;
      tx += dx;
      ty += dy;
    }
    tx = x - dx;
    ty = y - dy;
    while (tx >= 0 && tx < gridSize && ty >= 0 && ty < gridSize && board[ty][tx] == color) {
      count++;
      tx -= dx;
      ty -= dy;
    }
    return count;
  }

  PlayerColor checkWinner() {
    if (blackSeedsRemaining < 3) return PlayerColor.white;
    if (whiteSeedsRemaining < 3) return PlayerColor.black;
    if (currentPhase == GamePhase.movement) {
      if (!hasLegalMoves(currentPlayer)) {
        return currentPlayer == PlayerColor.black ? PlayerColor.white : PlayerColor.black;
      }
    }
    return PlayerColor.none;
  }

  bool hasLegalMoves(PlayerColor color) {
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (board[y][x] == color) {
          final neighbors = [
            Point(x + 1, y), Point(x - 1, y),
            Point(x, y + 1), Point(x, y - 1)
          ];
          for (var p in neighbors) {
            if (p.x >= 0 && p.x < gridSize && p.y >= 0 && p.y < gridSize) {
              if (board[p.y][p.x] == PlayerColor.none) {
                if (!wouldFormMoreThanThree(Point(x, y), p, color)) {
                  return true;
                }
              }
            }
          }
        }
      }
    }
    return false;
  }
}
