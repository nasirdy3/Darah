import 'dart:math';
import 'package:flutter/material.dart';
import '../progression/levels.dart';

class LevelNode {
  LevelNode({
    required this.level,
    required this.pos,
    required this.isUnlocked,
    required this.stars,
  });
  final LevelDefinition level;
  final Offset pos;
  final bool isUnlocked;
  final int stars;
}

class CandyMapPainter extends CustomPainter {
  CandyMapPainter({
    required this.nodes,
    required this.scrollOffset,
    required this.accentColor,
  });

  final List<LevelNode> nodes;
  final double scrollOffset;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    // Draw parchment texture
    _drawParchmentTexture(canvas, size);

    // Draw hand-drawn path
    _drawHandDrawnPath(canvas);

    // Draw wax seal nodes
    for (final node in nodes) {
      _drawWaxSeal(canvas, node);
    }
  }

  void _drawParchmentTexture(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // Base parchment color
    final parchmentPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFFF8E1), // Light cream
          const Color(0xFFFFF3E0), // Warm cream
          const Color(0xFFFFECB3), // Aged yellow
        ],
      ).createShader(rect);
    
    canvas.drawRect(rect, parchmentPaint);

    // Coffee stains and aged spots
    final random = Random(42);
    for (var i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 20 + random.nextDouble() * 40;
      
      final stainPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFD7C0AE).withOpacity(0.3),
            const Color(0xFFD7C0AE).withOpacity(0.1),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));
      
      canvas.drawCircle(Offset(x, y), radius, stainPaint);
    }

    // Subtle vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [
          Colors.transparent,
          const Color(0xFFD7C0AE).withOpacity(0.2),
        ],
      ).createShader(rect);
    
    canvas.drawRect(rect, vignette);
  }

  void _drawHandDrawnPath(Canvas canvas) {
    if (nodes.length < 2) return;

    // Hand-drawn style path
    final pathPaint = Paint()
      ..color = const Color(0xFF8D6E63).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(nodes.first.pos.dx, nodes.first.pos.dy);
    
    for (var i = 0; i < nodes.length - 1; i++) {
      final p1 = nodes[i].pos;
      final p2 = nodes[i + 1].pos;
      
      // Add slight wobble for hand-drawn effect
      final random = Random(i);
      final wobble1 = Offset(random.nextDouble() * 4 - 2, random.nextDouble() * 4 - 2);
      final wobble2 = Offset(random.nextDouble() * 4 - 2, random.nextDouble() * 4 - 2);
      
      final midX = (p1.dx + p2.dx) / 2 + wobble1.dx;
      final midY = (p1.dy + p2.dy) / 2 + wobble1.dy;
      
      path.quadraticBezierTo(midX, midY, p2.dx + wobble2.dx, p2.dy + wobble2.dy);
    }
    
    canvas.drawPath(path, pathPaint);

    // Double line for emphasis
    final doublePath = Paint()
      ..color = const Color(0xFF8D6E63).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(path, doublePath);
  }

  void _drawWaxSeal(Canvas canvas, LevelNode node) {
    final center = node.pos;
    final radius = node.isUnlocked ? 38.0 : 34.0;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center.translate(0, 5), radius, shadowPaint);

    // Wax seal base
    final waxColor = node.isUnlocked 
        ? const Color(0xFFD4AF37) // Gold wax
        : const Color(0xFF8D6E63); // Brown wax

    final waxPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 1.0,
        colors: [
          waxColor.withOpacity(0.9),
          waxColor,
          waxColor.withOpacity(0.8),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, waxPaint);

    // Embossed texture (circular ridges)
    for (var i = 0; i < 3; i++) {
      final ridgeRadius = radius * (0.3 + i * 0.2);
      final ridgePaint = Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, ridgeRadius, ridgePaint);
    }

    // Highlight edge
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, radius - 2, highlightPaint);

    // Level number (embossed)
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${node.level.id}',
        style: TextStyle(
          color: node.isUnlocked 
              ? const Color(0xFF3E2723) // Dark on gold
              : Colors.white.withOpacity(0.6), // Light on brown
          fontSize: 22,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: node.isUnlocked 
                  ? Colors.white.withOpacity(0.5)
                  : Colors.black.withOpacity(0.3),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    
    textPainter.paint(
      canvas,
      center.translate(-textPainter.width / 2, -textPainter.height / 2),
    );

    // Stars (gold embossed)
    if (node.isUnlocked && node.stars > 0) {
      _drawEmbossedStars(canvas, center, radius, node.stars);
    }

    // Lock icon if locked
    if (!node.isUnlocked) {
      const icon = Icons.lock_rounded;
      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: 18,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: Colors.white.withOpacity(0.4),
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      iconPainter.paint(
        canvas,
        center.translate(-iconPainter.width / 2, radius * 0.6),
      );
    }
  }

  void _drawEmbossedStars(Canvas canvas, Offset center, double radius, int stars) {
    const starCount = 3;
    final spacing = pi * 0.22;
    
    for (var i = 0; i < starCount; i++) {
      final angle = -pi / 2 + (i - 1) * spacing;
      final starPos = center.translate(
        cos(angle) * (radius + 12),
        sin(angle) * (radius + 12),
      );
      
      final filled = i < stars;
      
      // Star shadow (embossed effect)
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      _drawStarShape(canvas, starPos.translate(1, 1), 7, shadowPaint);
      
      // Star fill
      final starPaint = Paint()
        ..color = filled 
            ? const Color(0xFFFFD54F) 
            : const Color(0xFFD7C0AE).withOpacity(0.3);
      _drawStarShape(canvas, starPos, 7, starPaint);
      
      // Star highlight
      if (filled) {
        final highlightPaint = Paint()
          ..color = Colors.white.withOpacity(0.5);
        _drawStarShape(canvas, starPos.translate(-0.5, -0.5), 5, highlightPaint);
      }
    }
  }

  void _drawStarShape(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final step = pi / 5;
    for (var i = 0; i < 10; i++) {
      final r = (i % 2 == 0) ? size : size / 2;
      final angle = i * step - pi / 2;
      final p = center.translate(cos(angle) * r, sin(angle) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CandyMapPainter oldDelegate) => true;
}
