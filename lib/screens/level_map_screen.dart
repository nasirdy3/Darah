import 'dart:math';
import 'package:flutter/material.dart';

import '../progression/levels.dart';
import '../state/profile_store.dart';
import '../state/settings_store.dart';
import '../widgets/candy_map_painter.dart';
import 'game_screen.dart';

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key, required this.settings, required this.profile});
  final SettingsStore settings;
  final ProfileStore profile;

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Scroll to the latest unlocked level
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLatest();
    });
  }

  void _scrollToLatest() {
    int latestIdx = 0;
    for (var i = 0; i < levels.length; i++) {
      if (widget.profile.isLevelUnlocked(levels[i].id)) {
        latestIdx = i;
      }
    }
    
    final size = MediaQuery.of(context).size;
    const itemHeight = 120.0;
    final totalHeight = levels.length * itemHeight + 200;
    final dy = totalHeight - 100 - (latestIdx * itemHeight);
    
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        (dy - size.height / 2).clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const itemHeight = 120.0;
    final totalHeight = levels.length * itemHeight + 200;

    final List<LevelNode> nodes = [];
    for (var i = 0; i < levels.length; i++) {
      final level = levels[i];
      // Winding logic
      final row = i;
      final t = row * 0.4;
      final dx = size.width / 2 + sin(t) * (size.width * 0.3);
      final dy = totalHeight - 100 - (i * itemHeight);
      
      nodes.add(LevelNode(
        level: level,
        pos: Offset(dx, dy),
        isUnlocked: widget.profile.isLevelUnlocked(level.id),
        stars: widget.profile.starsFor(level.id),
      ));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: GestureDetector(
              onTapUp: (details) {
                final local = details.localPosition;
                for (final node in nodes) {
                  final dist = (node.pos - local).distance;
                  if (dist < 40 && node.isUnlocked) {
                    _startLevel(node.level);
                    break;
                  }
                }
              },
              child: CustomPaint(
                size: Size(size.width, totalHeight),
                painter: CandyMapPainter(
                  nodes: nodes,
                  scrollOffset: 0,
                  accentColor: const Color(0xFF4DD0E1),
                ),
              ),
            ),
          ),
          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 12, left: 16, right: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD54F), size: 20),
                        const SizedBox(width: 8),
                        Text('${widget.profile.coins}', 
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startLevel(LevelDefinition level) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          settings: widget.settings,
          profile: widget.profile,
          level: level,
        ),
      ),
    ).then((_) => setState(() {}));
  }
}
