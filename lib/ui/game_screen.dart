import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/game_state.dart';
import '../logic/models.dart';
import '../logic/data_manager.dart';
import 'board_painter.dart';

class DaraGameScreen extends StatelessWidget {
  const DaraGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0F0A),
      body: SafeArea(
        child: Consumer<GameState>(
          builder: (context, state, _) {
            // Show win overlay if game is over
            if (state.isGameOver) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showResultDialog(context, state);
              });
            }
            return Column(
              children: [
                _buildTopBar(context, state),
                const SizedBox(height: 8),
                _buildPhaseIndicator(state),
                const SizedBox(height: 12),
                _buildBoardArea(context, state),
                const SizedBox(height: 16),
                _buildStatusBar(state),
                const SizedBox(height: 16),
                _buildControlRow(context, state),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─────────────── TOP BAR ────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, GameState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white60),
          ),
          Expanded(
            child: Center(
              child: Text(
                'DARA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  shadows: [Shadow(color: Colors.orange.withOpacity(0.6), blurRadius: 12)],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _showResetDialog(context, state),
            icon: const Icon(Icons.refresh, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  // ─────────────── PHASE INDICATOR ────────────────────────────────
  Widget _buildPhaseIndicator(GameState state) {
    final phase = state.engine.currentPhase;
    final player = state.engine.currentPlayer;
    final isBlack = player == PlayerColor.black;

    String phaseLabel;
    Color phaseColor;
    if (phase == GamePhase.placement) {
      phaseLabel = '◆  PLACEMENT PHASE';
      phaseColor = const Color(0xFF90CAF9);
    } else if (phase == GamePhase.movement) {
      phaseLabel = '▶  MOVEMENT PHASE';
      phaseColor = const Color(0xFFA5D6A7);
    } else {
      phaseLabel = '✕  CAPTURE — Remove an opponent\'s seed';
      phaseColor = const Color(0xFFEF9A9A);
    }

    return Column(
      children: [
        Text(
          phaseLabel,
          style: TextStyle(
            color: phaseColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _seedDot(isBlack ? Colors.white : Colors.white38, 6),
            const SizedBox(width: 8),
            Text(
              isBlack ? 'BLACK\'S TURN' : 'WHITE\'S TURN',
              style: TextStyle(
                color: isBlack ? Colors.white : const Color(0xFFBFBFBF),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 8),
            _seedDot(isBlack ? Colors.white38 : Colors.white, 6),
          ],
        ),
      ],
    );
  }

  Widget _seedDot(Color color, double size) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  // ─────────────── BOARD AREA ──────────────────────────────────────
  Widget _buildBoardArea(BuildContext context, GameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: const Color(0xFF8D6E63).withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                return _buildBoard(ctx, state, constraints);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context, GameState state, BoxConstraints constraints) {
    final gridSize = state.engine.gridSize;
    final cellSize = constraints.maxWidth / gridSize;
    final validTargets = state.getValidMoveTargets();

    return Stack(
      children: [
        // ── Board painter ─────────────────────────────────────────
        CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: DaraBoardPainter(
            gridSize: gridSize,
            highlightedCells: validTargets,
          ),
        ),

        // ── Seeds (animated) ──────────────────────────────────────
        ...List.generate(gridSize, (y) {
          return List.generate(gridSize, (x) {
            final occupant = state.engine.board[y][x];
            if (occupant == PlayerColor.none) return const SizedBox.shrink();

            final isSelected = state.selectedSeed == Point(x, y);
            final isCapturable = state.capturableKeys.contains('$x,$y');

            return AnimatedPositioned(
              key: ValueKey('s_${x}_$y'),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              left: x * cellSize,
              top: y * cellSize,
              width: cellSize,
              height: cellSize,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('seed_${x}_$y'),
                  tween: Tween(begin: 0.4, end: 1.0),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.elasticOut,
                  builder: (_, scale, __) => Transform.scale(
                    scale: scale,
                    child: Consumer<DataManager>(
                      builder: (context, data, _) => CustomPaint(
                        size: Size(cellSize * 0.78, cellSize * 0.78),
                        painter: DaraSeedPainter(
                          color: occupant == PlayerColor.black ? Colors.black87 : Colors.white,
                          isSelected: isSelected,
                          isCapturable: isCapturable,
                          skinId: occupant == PlayerColor.black ? 'classic' : data.selectedSeedColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).whereType<Widget>().toList();
        }).expand((x) => x),

        // ── Valid move indicators ─────────────────────────────────
        ...validTargets.map((t) {
          final x = t[0], y = t[1];
          return Positioned(
            left: x * cellSize + cellSize * 0.35,
            top: y * cellSize + cellSize * 0.35,
            width: cellSize * 0.3,
            height: cellSize * 0.3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D).withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),

        // ── Tap overlay ───────────────────────────────────────────
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridSize,
          ),
          itemCount: gridSize * gridSize,
          itemBuilder: (ctx, index) {
            final x = index % gridSize;
            final y = index ~/ gridSize;
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => state.handleTap(x, y),
              child: const SizedBox.expand(),
            );
          },
        ),
      ],
    );
  }

  // ─────────────── STATUS BAR ──────────────────────────────────────
  Widget _buildStatusBar(GameState state) {
    final e = state.engine;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _playerCard('BLACK', e.blackSeedsRemaining,
              e.currentPlayer == PlayerColor.black, Colors.black87),
          _seedCountsInfo(e),
          _playerCard('WHITE', e.whiteSeedsRemaining,
              e.currentPlayer == PlayerColor.white, Colors.white),
        ],
      ),
    );
  }

  Widget _playerCard(String label, int seeds, bool isActive, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF4E342E).withOpacity(0.9)
            : const Color(0xFF2A1A14).withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? const Color(0xFFFF8A65).withOpacity(0.7)
              : Colors.white12,
          width: isActive ? 1.5 : 0.8,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: const Color(0xFFFF5722).withOpacity(0.25), blurRadius: 12)]
            : [],
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
              ),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$seeds',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text('seeds', style: TextStyle(color: isActive ? Colors.white54 : Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _seedCountsInfo(engine) {
    return Text(
      'vs',
      style: TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.bold),
    );
  }

  // ─────────────── CONTROLS ────────────────────────────────────────
  Widget _buildControlRow(BuildContext context, GameState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ctrlButton(
          icon: Icons.undo_rounded,
          label: 'UNDO',
          onTap: () {},  // TODO: implement undo
        ),
        const SizedBox(width: 32),
        _ctrlButton(
          icon: Icons.lightbulb_rounded,
          label: 'HINT',
          onTap: () {},  // TODO: implement hint
          color: const Color(0xFFFFB74D),
        ),
      ],
    );
  }

  Widget _ctrlButton({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF3E2723),
              shape: BoxShape.circle,
              border: Border.all(color: (color ?? Colors.white).withOpacity(0.2)),
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: color ?? Colors.white60, size: 26),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─────────────── DIALOGS ─────────────────────────────────────────
  void _showResultDialog(BuildContext context, GameState state) {
    final isBlackWin = state.result == GameResult.blackWins;
    final isHuman = isBlackWin; // Human is always black in AI game
    final title = isHuman ? '🏆 Victory!' : '💀 Defeated!';
    final sub = isBlackWin ? 'Black wins the match' : 'White wins the match';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isHuman
                  ? [const Color(0xFF2E1A12), const Color(0xFF4E342E)]
                  : [const Color(0xFF1A0A0A), const Color(0xFF3E1A1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHuman ? const Color(0xFFFFB74D) : Colors.red.shade900,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 38, color: Colors.white)),
              const SizedBox(height: 8),
              Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 1)),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _dialogBtn('MENU', Colors.white24, () {
                    Navigator.of(context)
                      ..pop()
                      ..pop();
                  }),
                  _dialogBtn('PLAY AGAIN', const Color(0xFF8D6E63), () {
                    Navigator.of(context).pop();
                    state.reset();
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      ),
    );
  }

  void _showResetDialog(BuildContext context, GameState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2E1A12),
        title: const Text('Restart?', style: TextStyle(color: Colors.white)),
        content: const Text('Start the game over from the beginning?', style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () { Navigator.pop(context); state.reset(); },
            child: const Text('Restart', style: TextStyle(color: Color(0xFFFF8A65))),
          ),
        ],
      ),
    );
  }
}
