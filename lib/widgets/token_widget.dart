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
    this.pulse = 0.0,
  });

  final Player player;
  final double size;
  final SeedSkin skin;
  final bool glow;
  final bool selected;
  final bool aiSelected;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    if (player == Player.none) return const SizedBox.shrink();

    final palette = player == Player.p1 ? skin.p1 : skin.p2;
    final glowColor = palette.glow;
    final pulseBoost = (0.2 + 0.6 * pulse).clamp(0.2, 0.9);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          if (glow)
            BoxShadow(
              color: glowColor.withOpacity(0.5 + 0.2 * pulse),
              blurRadius: 16 + 10 * pulse,
              spreadRadius: 2 + pulseBoost * 1.5,
            ),
          if (selected)
            BoxShadow(
              color: Colors.white.withOpacity(0.3 + 0.2 * pulse),
              blurRadius: 14 + 6 * pulse,
              spreadRadius: 1 + pulseBoost,
            ),
          if (aiSelected)
            BoxShadow(
              color: glowColor.withOpacity(0.4 + 0.3 * pulse),
              blurRadius: 14 + 8 * pulse,
              spreadRadius: 1 + pulseBoost,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(2, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.rim,
            palette.base,
            palette.base,
            Colors.black.withOpacity(0.4),
          ],
          stops: const [0.0, 0.2, 0.6, 1.0],
        ),
      ),
      child: Container(
        margin: EdgeInsets.all(size * 0.08),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.16),
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.4),
            radius: 1.2,
            colors: [
              Colors.white.withOpacity(0.5), // Specular highlight
              palette.base,
              palette.base,
              palette.rim,
            ],
            stops: const [0.0, 0.2, 0.6, 1.0],
          ),
        ),
      ),
    );
  }
}
