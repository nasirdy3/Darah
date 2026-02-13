import 'package:flutter/material.dart';

import '../progression/levels.dart';
import '../state/profile_store.dart';
import '../state/settings_store.dart';
import 'game_screen.dart';

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key, required this.settings, required this.profile});
  final SettingsStore settings;
  final ProfileStore profile;

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Level Map'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD54F), size: 18),
                  const SizedBox(width: 6),
                  Text('${widget.profile.coins}', style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF120E0B), Color(0xFF080705)],
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: levels.length,
          itemBuilder: (context, index) {
            final level = levels[index];
            final unlocked = widget.profile.isLevelUnlocked(level.id);
            final stars = widget.profile.starsFor(level.id);

            return GestureDetector(
              onTap: unlocked
                  ? () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => GameScreen(
                                settings: widget.settings,
                                profile: widget.profile,
                                level: level,
                              ),
                            ),
                          )
                          .then((_) => setState(() {}));
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: unlocked ? const Color(0xFF1F1812) : const Color(0xFF14100C),
                  border: Border.all(
                    color: unlocked ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${level.id}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: unlocked ? Colors.white : Colors.white.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (!unlocked)
                      Icon(Icons.lock, size: 18, color: Colors.white.withOpacity(0.25))
                    else
                      _Stars(stars: stars),
                    const SizedBox(height: 8),
                    Text(
                      level.aiTier.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.1,
                        color: unlocked ? Colors.white.withOpacity(0.6) : Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < stars;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          color: filled ? const Color(0xFFFFD54F) : Colors.white.withOpacity(0.3),
          size: 18,
        );
      }),
    );
  }
}
