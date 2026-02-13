import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ai/ai_player.dart';
import '../audio/audio_manager.dart';
import '../game/config.dart';
import '../game/move_generator.dart';
import '../game/rules.dart';
import '../game/state.dart';
import '../game/types.dart';
import '../state/settings_store.dart';
import '../widgets/board_painter.dart';
import '../widgets/token_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.settings});
  final SettingsStore settings;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameState gs;
  late BoardConfig cfg;
  final audio = const AudioManager();

  int? selectedCell; // for movement
  String toast = '';
  bool gameOver = false;
  Player winner = Player.none;

  // animations
  late AnimationController toastCtrl;

  @override
  void initState() {
    super.initState();
    _newGame();
    toastCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
  }

  void _newGame() {
    cfg = BoardConfig(widget.settings.boardSize);
    gs = GameState(cfg);
    selectedCell = null;
    toast = '';
    gameOver = false;
    winner = Player.none;
  }

  Player get human => widget.settings.playerIsP1 ? Player.p1 : Player.p2;
  Player get aiSide => human.opponent;

  bool get isHumansTurn {
    if (!widget.settings.vsAi) return true;
    return gs.turn == human || gs.phase == Phase.capture && gs.captureBy == human;
  }

  Future<void> _showToast(String msg) async {
    setState(() => toast = msg);
    await toastCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await toastCtrl.reverse();
  }

  Future<void> _maybeAiTurn() async {
    if (!widget.settings.vsAi) return;
    if (gameOver) return;

    final aiShouldPlay = (gs.phase == Phase.capture && gs.captureBy == aiSide) || (gs.phase != Phase.capture && gs.turn == aiSide);
    if (!aiShouldPlay) return;

    final ai = AIPlayer(level: widget.settings.aiLevel);
    // Give a tiny delay so the UI breathes
    await Future.delayed(const Duration(milliseconds: 140));

    final mv = await ai.chooseMove(gs.clone(), aiSide);
    if (!mounted || mv == null || gameOver) return;

    await _applyMove(mv, byAi: true);
  }

  Set<int> _highlightCells() {
    final n = cfg.size;
    final set = <int>{};

    if (gameOver) return set;

    if (gs.phase == Phase.capture) {
      // highlight all capturable opponent seeds
      final enemy = gs.captureBy.opponent;
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          if (gs.getCell(r, c) == enemy) set.add(r * n + c);
        }
      }
      return set;
    }

    if (gs.phase == Phase.placement) {
      // highlight legal placements for current turn (for feel)
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          if (Rules.isLegalPlace(gs, r, c)) set.add(r * n + c);
        }
      }
      return set;
    }

    // movement: if selected, show destinations
    if (selectedCell != null) {
      final r = selectedCell! ~/ n;
      final c = selectedCell! % n;
      const dirs = [
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1],
      ];
      for (final d in dirs) {
        final tr = r + d[0];
        final tc = c + d[1];
        if (!cfg.inBounds(tr, tc)) continue;
        if (Rules.isLegalStep(gs, r, c, tr, tc)) set.add(tr * n + tc);
      }
    }
    return set;
  }

  Future<void> _applyMove(Move mv, {required bool byAi}) async {
    if (gameOver) return;

    switch (mv.kind) {
      case MoveKind.place:
        Rules.applyPlace(gs, mv.r!, mv.c!);
        await audio.playPlace();
        break;
      case MoveKind.step:
        Rules.applyStep(gs, mv.fr!, mv.fc!, mv.tr!, mv.tc!);
        await audio.playMove();
        break;
      case MoveKind.capture:
        Rules.applyCapture(gs, mv.capR!, mv.capC!);
        await audio.playMove();
        HapticFeedback.vibrate();
        break;
    }

    // clear selection if turn switched
    if (gs.phase != Phase.movement) {
      selectedCell = null;
    }

    // check win
    if (Rules.isWin(gs)) {
      winner = Rules.winner(gs);
      gameOver = true;
      if (winner == human) {
        await audio.playWin();
      } else {
        await audio.playLose();
      }
    }

    if (!mounted) return;
    setState(() {});

    await _maybeAiTurn();
  }

  Future<void> _onTapCell(int idx) async {
    if (gameOver) return;

    final n = cfg.size;
    final r = idx ~/ n;
    final c = idx % n;

    // If vs AI and not human's turn, ignore taps
    if (widget.settings.vsAi) {
      final humanCanAct = (gs.phase == Phase.capture && gs.captureBy == human) || (gs.phase != Phase.capture && gs.turn == human);
      if (!humanCanAct) return;
    }

    if (gs.phase == Phase.capture) {
      if (!Rules.isLegalCapture(gs, r, c)) {
        await _showToast('Select an opponent seed to remove');
        return;
      }
      await _applyMove(Move.capture(r, c), byAi: false);
      return;
    }

    if (gs.phase == Phase.placement) {
      if (!Rules.isLegalPlace(gs, r, c)) {
        await _showToast('Invalid placement (no 3-in-row in placement)');
        return;
      }
      await _applyMove(Move.place(r, c), byAi: false);
      return;
    }

    // movement
    final cellPlayer = gs.getCell(r, c);

    if (selectedCell == null) {
      if (cellPlayer != gs.turn) {
        await _showToast('Select one of your seeds');
        return;
      }
      setState(() => selectedCell = idx);
      return;
    }

    // tap same to unselect
    if (selectedCell == idx) {
      setState(() => selectedCell = null);
      return;
    }

    final fr = selectedCell! ~/ n;
    final fc = selectedCell! % n;
    if (!Rules.isLegalStep(gs, fr, fc, r, c)) {
      await _showToast('Illegal move');
      return;
    }

    await _applyMove(Move.step(fr, fc, r, c), byAi: false);
  }

  @override
  void dispose() {
    toastCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = cfg.size;
    final legalHighlights = _highlightCells();

    final phaseLabel = switch (gs.phase) {
      Phase.placement => 'Placement',
      Phase.movement => 'Movement',
      Phase.capture => 'Capture',
    };

    final turnLabel = gs.phase == Phase.capture
        ? '${_playerName(gs.captureBy)} formed Dara — capture 1 seed'
        : '${_playerName(gs.turn)} to play';

    final p1Count = gs.remainingP1;
    final p2Count = gs.remainingP2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Darah'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _newGame());
              _maybeAiTurn();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _InfoPill(
                      title: turnLabel,
                      subtitle: 'Phase: $phaseLabel',
                      icon: gs.phase == Phase.capture ? Icons.flash_on_rounded : Icons.sports_esports,
                      danger: gs.phase == Phase.capture,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _CountCard(label: 'White', value: p1Count, active: gs.turn == Player.p1 || gs.captureBy == Player.p1)),
                  const SizedBox(width: 12),
                  Expanded(child: _CountCard(label: 'Black', value: p2Count, active: gs.turn == Player.p2 || gs.captureBy == Player.p2)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final side = min(constraints.maxWidth, constraints.maxHeight);
                      final boardSize = Size.square(side);
                      final cell = side / n;
                      final tokenSize = cell * 0.62;

                      return Stack(
                        children: [
                          GestureDetector(
                            onTapDown: (d) {
                              if (!isHumansTurn && widget.settings.vsAi) return;
                              final local = d.localPosition;
                              final hit = hitTestCell(localPos: local, boardSize: boardSize, n: n);
                              if (hit == null) return;
                              _onTapCell(hit);
                            },
                            child: CustomPaint(
                              size: boardSize,
                              painter: BoardPainter(
                                sizeN: n,
                                highlightCells: legalHighlights,
                                selectedCell: selectedCell,
                                captureMode: gs.phase == Phase.capture,
                              ),
                            ),
                          ),

                          // tokens
                          ...List.generate(n * n, (idx) {
                            final r = idx ~/ n;
                            final c = idx % n;
                            final p = gs.getCell(r, c);
                            if (p == Player.none) return const SizedBox.shrink();

                            final left = (c + 0.5) * cell - tokenSize / 2;
                            final top = (r + 0.5) * cell - tokenSize / 2;

                            final glow = (gs.phase == Phase.capture && p == gs.captureBy.opponent);

                            return AnimatedPositioned(
                              key: ValueKey('t_${idx}_${p.name}'),
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              left: left,
                              top: top,
                              width: tokenSize,
                              height: tokenSize,
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 180),
                                scale: 1.0,
                                child: TokenWidget(player: p, size: tokenSize, glow: glow),
                              ),
                            );
                          }),

                          if (gameOver)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          winner == Player.none ? 'Game Over' : '${_playerName(winner)} Wins!',
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                                        ),
                                        const SizedBox(height: 10),
                                        FilledButton(
                                          onPressed: () {
                                            setState(() => _newGame());
                                            _maybeAiTurn();
                                          },
                                          child: const Text('Play Again'),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Exit'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // toast
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 14,
                            child: FadeTransition(
                              opacity: CurvedAnimation(parent: toastCtrl, curve: Curves.easeOut),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF101010).withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                                  ),
                                  child: Text(toast, style: const TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  String _playerName(Player p) {
    switch (p) {
      case Player.p1:
        return 'White';
      case Player.p2:
        return 'Black';
      case Player.none:
        return 'None';
    }
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.title, required this.subtitle, required this.icon, this.danger = false});
  final String title;
  final String subtitle;
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: (danger ? const Color(0xFF5A1D1D) : const Color(0xFF1E1915)).withOpacity(0.85),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.black.withOpacity(0.25),
            ),
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Opacity(opacity: 0.75, child: Text(subtitle, style: const TextStyle(fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.value, required this.active});
  final String label;
  final int value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF15110E).withOpacity(0.88),
        border: Border.all(color: active ? const Color(0xFFFFD54F).withOpacity(0.25) : Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(opacity: 0.75, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
                const SizedBox(height: 4),
                Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Icon(active ? Icons.circle : Icons.circle_outlined, size: 18),
        ],
      ),
    );
  }
}
