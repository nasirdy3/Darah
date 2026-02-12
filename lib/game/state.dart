import 'types.dart';
import 'config.dart';

class GameState {
  GameState(this.cfg)
      : board = List<Player>.filled(cfg.size * cfg.size, Player.none),
        phase = Phase.placement,
        turn = Player.p1,
        placedP1 = 0,
        placedP2 = 0,
        remainingP1 = cfg.seedsPerPlayer(),
        remainingP2 = cfg.seedsPerPlayer(),
        captureBy = Player.none;

  final BoardConfig cfg;
  final List<Player> board;

  Phase phase;
  Player turn;

  int placedP1;
  int placedP2;

  int remainingP1;
  int remainingP2;

  Player captureBy;

  int idx(int r, int c) => r * cfg.size + c;
  Player getCell(int r, int c) => board[idx(r, c)];
  void setCell(int r, int c, Player v) => board[idx(r, c)] = v;

  bool allPlaced() => placedP1 >= cfg.seedsPerPlayer() && placedP2 >= cfg.seedsPerPlayer();

  GameState clone() {
    final gs = GameState(BoardConfig(cfg.size));
    gs.board.setAll(0, board);
    gs.phase = phase;
    gs.turn = turn;
    gs.placedP1 = placedP1;
    gs.placedP2 = placedP2;
    gs.remainingP1 = remainingP1;
    gs.remainingP2 = remainingP2;
    gs.captureBy = captureBy;
    return gs;
  }
}
