import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/game_state.dart';
import '../logic/data_manager.dart';
import 'game_screen.dart';
import 'main_menu.dart' show Difficulty;

// ══════════════════════════════════════════════════════════════════
//  LEVEL MAP SCREEN — Candy Crush–style zigzag node map
// ══════════════════════════════════════════════════════════════════
class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({super.key});

  static const List<_LevelData> _levels = [
    _LevelData(1,  Difficulty.easy,   true),
    _LevelData(2,  Difficulty.easy,   true),
    _LevelData(3,  Difficulty.easy,   true),
    _LevelData(4,  Difficulty.medium, true),
    _LevelData(5,  Difficulty.hard,   false, boss: true),
    _LevelData(6,  Difficulty.medium, false),
    _LevelData(7,  Difficulty.medium, false),
    _LevelData(8,  Difficulty.medium, false),
    _LevelData(9,  Difficulty.hard,   false),
    _LevelData(10, Difficulty.legend, false, boss: true),
    _LevelData(11, Difficulty.hard,   false),
    _LevelData(12, Difficulty.hard,   false),
    _LevelData(13, Difficulty.legend, false),
    _LevelData(14, Difficulty.legend, false),
    _LevelData(15, Difficulty.legend, false, boss: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0603),
      body: Stack(
        children: [
          // Scrollable zigzag node map
          CustomScrollView(
            reverse: true,
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: false,
                floating: false,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text('LEVEL MAP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 3)),
                centerTitle: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                sliver: Consumer<DataManager>(
                  builder: (context, data, _) {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final level = _levels[i];
                          final isUnlocked = level.number <= data.unlockedLevels;
                          return _LevelNode(
                            level: level.copyWith(unlocked: isUnlocked),
                            onTap: isUnlocked ? () => _launch(context, level) : null,
                          );
                        },
                        childCount: _levels.length,
                      ),
                    );
                  }
                ),
              ),
            ],
          ),
          // Bottom coin/stars bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Consumer<DataManager>(
                    builder: (context, data, _) => _chip(Icons.stars_rounded, '${data.unlockedLevels}', Colors.amber),
                  ),
                  const SizedBox(width: 24),
                  Consumer<DataManager>(
                    builder: (context, data, _) => _chip(Icons.monetization_on_rounded, '${data.coins}', Colors.orange),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String val, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.withOpacity(0.4)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: c, size: 18),
      const SizedBox(width: 6),
      Text(val, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 14)),
    ]),
  );

  void _launch(BuildContext context, _LevelData level) {
    final data = Provider.of<DataManager>(context, listen: false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => GameState(
          gridSize: 5,
          isAiGame: true,
          difficultyDepth: level.diff.depth,
          onWin: () {
            data.unlockNextLevel(level.number);
            data.addCoins(50 + (level.diff.depth * 10));
          },
        ),
        child: const DaraGameScreen(),
      ),
    ));
  }
}

// ── Level data ────────────────────────────────────────────────────
class _LevelData {
  final int number;
  final Difficulty diff;
  final bool unlocked;
  final bool boss;
  const _LevelData(this.number, this.diff, this.unlocked, {this.boss = false});

  _LevelData copyWith({bool? unlocked}) => _LevelData(number, diff, unlocked ?? this.unlocked, boss: boss);
}

// ── Level node ────────────────────────────────────────────────────
class _LevelNode extends StatelessWidget {
  final _LevelData level;
  final VoidCallback? onTap;
  const _LevelNode({required this.level, this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = level.diff;
    final locked = !level.unlocked;
    final size = level.boss ? 74.0 : 60.0;

    // Zigzag: odd numbers lean right, even lean left
    final isRight = level.number.isOdd;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isRight) _buildConnector(),
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: size, height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: locked
                      ? [Colors.grey.shade700, Colors.grey.shade900]
                      : [d.color.withOpacity(0.9), d.color.withOpacity(0.35)],
                ),
                border: Border.all(
                  color: locked ? Colors.grey.shade800 : d.color,
                  width: level.boss ? 3 : 2,
                ),
                boxShadow: locked ? [] : [
                  BoxShadow(color: d.color.withOpacity(0.5), blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: Center(
                child: locked
                    ? const Icon(Icons.lock_rounded, color: Colors.white30, size: 22)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            level.boss ? d.icon : '${level.number}',
                            style: TextStyle(
                              fontSize: level.boss ? 26 : 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (!level.boss)
                            Text(d.icon, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
              ),
            ),
          ),
          if (isRight) _buildConnector(),
        ],
      ),
    );
  }

  Widget _buildConnector() {
    return Container(
      width: 40, height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: level.unlocked ? level.diff.color.withOpacity(0.4) : Colors.white12,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
