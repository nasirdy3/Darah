import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/game_state.dart';
import '../logic/data_manager.dart';
import 'game_screen.dart';
import 'level_map.dart';

// ── Difficulty preset ────────────────────────────────────────────
enum Difficulty {
  easy(label: 'Easy', icon: '☀', depth: 1, color: Color(0xFFA5D6A7)),
  medium(label: 'Medium', icon: '⚡', depth: 3, color: Color(0xFFFFCC80)),
  hard(label: 'Hard', icon: '🔥', depth: 5, color: Color(0xFFEF9A9A)),
  legend(label: 'Legend', icon: '☠', depth: 7, color: Color(0xFFCE93D8));

  final String label;
  final String icon;
  final int depth;
  final Color color;
  const Difficulty({required this.label, required this.icon, required this.depth, required this.color});
}

// ══════════════════════════════════════════════════════════════════
//  MAIN MENU
// ══════════════════════════════════════════════════════════════════
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0805),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -100, left: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF5D4037).withOpacity(0.18)),
            ),
          ),
          Positioned(
            top: 20, right: 28,
            child: SafeArea(
              child: Consumer<DataManager>(
                builder: (context, data, _) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on_rounded, color: Colors.orange, size: 18),
                      const SizedBox(width: 6),
                      Text('${data.coins}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  _buildLogo(),
                  const SizedBox(height: 12),
                  const Text(
                    'TRADITIONAL AFRICAN STRATEGY',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  _MenuButton(label: 'PLAY vs AI', icon: Icons.smart_toy_rounded, color: const Color(0xFF8D6E63), onTap: () => _showDifficultySheet(context)),
                  const SizedBox(height: 14),
                  _MenuButton(label: '2 PLAYERS', icon: Icons.people_alt_rounded, color: const Color(0xFF546E7A), onTap: () => _launchGame(context, isAi: false)),
                  const SizedBox(height: 14),
                   _MenuButton(label: 'LEVEL MAP', icon: Icons.map_rounded, color: const Color(0xFF558B2F), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LevelMapScreen()))),
                  const SizedBox(height: 14),
                  _MenuButton(label: 'STORE', icon: Icons.shopping_bag_rounded, color: const Color(0xFFAD1457), onTap: () => _showStore(context)),
                  const SizedBox(height: 14),
                  _MenuButton(label: 'HOW TO PLAY', icon: Icons.menu_book_rounded, color: const Color(0xFF37474F), onTap: () => _showRules(context)),
                  const Spacer(),
                  const Text('DARA v1.0 • A Nigerian Heritage Game', textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [Color(0xFFFFCCBC), Color(0xFFFF7043), Color(0xFFFFF9C4)],
          ).createShader(r),
          child: const Text(
            'DARA',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w900, letterSpacing: 14, height: 1),
          ),
        ),
        const SizedBox(height: 4),
        Container(height: 2, width: 120, color: const Color(0xFF8D6E63).withOpacity(0.6)),
      ],
    );
  }

  void _showDifficultySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0F0A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('CHOOSE DIFFICULTY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 14)),
            const SizedBox(height: 24),
            ...Difficulty.values.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DifficultyTile(diff: d, onTap: () { Navigator.pop(context); _showGridSizeSheet(context, d); }),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showGridSizeSheet(BuildContext context, Difficulty diff) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0F0A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('BOARD SIZE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 14)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: _GridSizeTile(label: '5 × 5', sub: '6 seeds each', size: 5, diff: diff, ctx: context, sheetCtx: sheetCtx)),
              const SizedBox(width: 14),
              Expanded(child: _GridSizeTile(label: '6 × 6', sub: '12 seeds each', size: 6, diff: diff, ctx: context, sheetCtx: sheetCtx)),
            ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _launchGame(BuildContext context, {required bool isAi, int difficulty = 3, int gridSize = 5}) {
    final data = Provider.of<DataManager>(context, listen: false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => GameState(
          gridSize: gridSize, 
          isAiGame: isAi, 
          difficultyDepth: difficulty,
          onWin: () => data.addCoins(25), // Basic bonus for exhibition match
        ),
        child: const DaraGameScreen(),
      ),
    ));
  }

  void _showStore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0F0A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('SEED STORE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 14)),
            const SizedBox(height: 24),
            Consumer<DataManager>(
              builder: (context, data, _) => Row(
                children: [
                  _SkinItem(label: 'Classic', color: Colors.white, id: 'classic', current: data.selectedSeedColor, onTap: () => data.setSeedSkin('classic')),
                  const SizedBox(width: 14),
                  _SkinItem(label: 'Gold', color: Colors.amber, id: 'gold', current: data.selectedSeedColor, onTap: () => data.setSeedSkin('gold')),
                  const SizedBox(width: 14),
                  _SkinItem(label: 'Ebony', color: Colors.blueGrey, id: 'ebony', current: data.selectedSeedColor, onTap: () => data.setSeedSkin('ebony')),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1A0F0A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('HOW TO PLAY DARA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
              const Divider(color: Colors.white12, height: 24),
              const _RuleItem('Phase 1 — Placement', 'Take turns placing seeds. You may NOT form a line of 3 (Dara) during placement.'),
              const _RuleItem('Phase 2 — Movement', 'Move one seed one step (up/down/left/right). No diagonal. No jumping. Creating 4+ in a line is illegal.'),
              const _RuleItem('Forming a Dara', 'Align exactly 3 of your seeds in a straight line to capture one opponent\'s seed.'),
              const _RuleItem('Winning', 'Your opponent loses if they have fewer than 3 seeds, or no legal moves.'),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('GOT IT', style: TextStyle(color: Color(0xFFFF8A65), letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting Widgets ─────────────────────────────────────────────
class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MenuButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Text(label, style: TextStyle(color: color.withOpacity(0.95), fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 2)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.5), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  final Difficulty diff;
  final VoidCallback onTap;
  const _DifficultyTile({required this.diff, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: diff.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: diff.color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Text(diff.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 16),
            Text(diff.label, style: TextStyle(color: diff.color, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.5)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: diff.color.withOpacity(0.5), size: 14),
          ],
        ),
      ),
    );
  }
}

class _GridSizeTile extends StatelessWidget {
  final String label;
  final String sub;
  final int size;
  final Difficulty diff;
  final BuildContext ctx;
  final BuildContext sheetCtx;
  const _GridSizeTile({required this.label, required this.sub, required this.size, required this.diff, required this.ctx, required this.sheetCtx});

  @override
  Widget build(BuildContext bc) {
    return GestureDetector(
      onTap: () {
        final data = Provider.of<DataManager>(ctx, listen: false);
        Navigator.pop(sheetCtx);
        Navigator.of(ctx).push(MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => GameState(
              gridSize: size, 
              isAiGame: true, 
              difficultyDepth: diff.depth,
              onWin: () => data.addCoins(25),
            ),
            child: const DaraGameScreen(),
          ),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: const Color(0xFF2E1A12), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String title;
  final String body;
  const _RuleItem(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFFFF8A65), fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5)),
          const SizedBox(height: 3),
          Text(body, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }
}

class _SkinItem extends StatelessWidget {
  final String label;
  final Color color;
  final String id;
  final String current;
  final VoidCallback onTap;

  const _SkinItem({required this.label, required this.color, required this.id, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = current == id;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? color : Colors.white12, width: 2),
          ),
          child: Column(
            children: [
              Container(width: 24, height: 24, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [if (isSelected) BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)])),
              const SizedBox(height: 10),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
