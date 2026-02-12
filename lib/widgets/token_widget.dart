import 'package:flutter/material.dart';
import '../game/types.dart';

class TokenWidget extends StatelessWidget {
  const TokenWidget({super.key, required this.player, required this.size, this.glow = false});
  final Player player;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    if (player == Player.none) return const SizedBox.shrink();

    final isP1 = player == Player.p1;
    final base = isP1 ? const Color(0xFFEDE3D1) : const Color(0xFF1A1A1A);
    final rim = isP1 ? const Color(0xFFBFAF92) : const Color(0xFF4E4E4E);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          if (glow)
            BoxShadow(
              color: (isP1 ? const Color(0xFF00E5FF) : const Color(0xFFFFD54F)).withOpacity(0.45),
              blurRadius: 18,
              spreadRadius: 2,
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
            base.withOpacity(0.98),
            base.withOpacity(0.85),
            rim.withOpacity(0.95),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        border: Border.all(color: Colors.white.withOpacity(isP1 ? 0.25 : 0.12), width: 1.4),
      ),
    );
  }
}
