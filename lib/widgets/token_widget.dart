import 'package:flutter/material.dart';
import '../game/types.dart';
import '../skins/skins.dart';

class TokenWidget extends StatelessWidget {
  const TokenWidget({
    super.key,
    required this.player,
    required this.size,
    required this.skin,
    this.glow = false,
    this.selected = false,
    this.aiSelected = false,
  });

  final Player player;
  final double size;
  final SeedSkin skin;
  final bool glow;
  final bool selected;
  final bool aiSelected;

  @override
  Widget build(BuildContext context) {
    if (player == Player.none) return const SizedBox.shrink();

    final palette = player == Player.p1 ? skin.p1 : skin.p2;
    final glowColor = palette.glow;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          if (glow)
            BoxShadow(
              color: glowColor.withOpacity(0.55),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          if (selected)
            BoxShadow(
              color: Colors.white.withOpacity(0.35),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          if (aiSelected)
            BoxShadow(
              color: glowColor.withOpacity(0.45),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            palette.base.withOpacity(0.98),
            palette.base.withOpacity(0.86),
            palette.rim.withOpacity(0.95),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(player == Player.p1 ? 0.25 : 0.12),
          width: 1.4,
        ),
      ),
    );
  }
}
