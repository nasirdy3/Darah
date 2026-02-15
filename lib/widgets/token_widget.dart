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

    final isWhite = player == Player.p1;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          // Glow effects
          if (glow)
            BoxShadow(
              color: const Color(0xFFFFB300).withOpacity(0.5 + 0.2 * pulse),
              blurRadius: 18 + 12 * pulse,
              spreadRadius: 3 + 2 * pulse,
            ),
          if (selected)
            BoxShadow(
              color: const Color(0xFFFFD54F).withOpacity(0.6 + 0.3 * pulse),
              blurRadius: 16 + 10 * pulse,
              spreadRadius: 2 + 2 * pulse,
            ),
          if (aiSelected)
            BoxShadow(
              color: const Color(0xFF4DD0E1).withOpacity(0.5 + 0.3 * pulse),
              blurRadius: 16 + 10 * pulse,
              spreadRadius: 2 + 2 * pulse,
            ),
          // Cast shadow on board
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: size * 0.15,
            offset: Offset(size * 0.03, size * 0.08),
          ),
        ],
      ),
      child: isWhite ? _buildIvoryToken() : _buildEbonyToken(),
    );
  }

  Widget _buildIvoryToken() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 1.0,
          colors: [
            const Color(0xFFFFFBF0), // Bright ivory highlight
            const Color(0xFFFFF8E1), // Cream ivory
            const Color(0xFFFFF3E0), // Warm ivory
            const Color(0xFFE8D5C4), // Darker edge
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        boxShadow: [
          // Inner shadow for depth
          BoxShadow(
            color: const Color(0xFFD7C0AE).withOpacity(0.3),
            blurRadius: size * 0.08,
            offset: Offset(size * 0.02, size * 0.02),
            spreadRadius: -size * 0.02,
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(size * 0.05),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 0.6,
            colors: [
              Colors.white.withOpacity(0.9), // Specular highlight
              Colors.white.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEbonyToken() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.3),
          radius: 1.2,
          colors: [
            const Color(0xFF3E2723), // Subtle brown highlight
            const Color(0xFF2D1F17), // Dark brown
            const Color(0xFF1A1410), // Deep charcoal
            const Color(0xFF0F0A08), // Almost black
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        boxShadow: [
          // Inner shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: size * 0.06,
            offset: Offset(size * 0.015, size * 0.015),
            spreadRadius: -size * 0.015,
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(size * 0.06),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.4),
            radius: 0.5,
            colors: [
              const Color(0xFF8D6E63).withOpacity(0.3), // Subtle warm highlight
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

