import 'dart:math';
import 'package:flutter/material.dart';
import '../skins/skins.dart';

class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.sizeN,
    required this.highlightCells,
    required this.hintCells,
    required this.selectedCell,
    required this.captureMode,
    required this.skin,
    required this.aiFromCell,
    required this.aiToCell,
    required this.aiCaptureCell,
    required this.pulse,
  });

  final int sizeN;
  final Set<int> highlightCells;
  final Set<int> hintCells;
  final int? selectedCell;
  final bool captureMode;
  final BoardSkin skin;
  final int? aiFromCell;
  final int? aiToCell;
  final int? aiCaptureCell;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Rich wood background with grain effect
    _drawWoodBackground(canvas, rect);

    // Beveled frame
    _drawBeveledFrame(canvas, rect);

    final cell = size.width / sizeN;

    // Subtle grid lines (wood grain separation)
    _drawWoodGrain(canvas, size, cell);

    // AI move trail
    if (aiFromCell != null && aiToCell != null) {
      _drawAiTrail(canvas, cell);
    }

    // Draw pits (carved indents)
    for (var r = 0; r < sizeN; r++) {
      for (var c = 0; c < sizeN; c++) {
        final idx = r * sizeN + c;
        final cx = (c + 0.5) * cell;
        final cy = (r + 0.5) * cell;
        
        _drawCarvedPit(canvas, Offset(cx, cy), cell, idx);
      }
    }

    // Highlight cells
    for (final idx in highlightCells) {
      final center = _cellCenter(idx, cell);
      _drawHighlight(canvas, center, cell, const Color(0xFF4DD0E1));
    }

    // Hint cells
    for (final idx in hintCells) {
      final center = _cellCenter(idx, cell);
      _drawHighlight(canvas, center, cell, const Color(0xFFFFB300));
    }

    // Selected cell
    if (selectedCell != null) {
      final center = _cellCenter(selectedCell!, cell);
      _drawSelection(canvas, center, cell);
    }

    // AI capture cell
    if (aiCaptureCell != null) {
      final center = _cellCenter(aiCaptureCell!, cell);
      _drawCaptureGlow(canvas, center, cell, pulse);
    }
  }

  void _drawWoodBackground(Canvas canvas, Rect rect) {
    // Base wood gradient
    final woodGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF3E2723), // Dark mahogany
          const Color(0xFF4A3428), // Medium brown
          const Color(0xFF3E2723), // Dark mahogany
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      woodGradient,
    );

    // Wood grain texture overlay
    final random = Random(42);
    final grainPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..strokeWidth = 0.5;

    for (var i = 0; i < 30; i++) {
      final y = random.nextDouble() * rect.height;
      final offset = random.nextDouble() * 20 - 10;
      canvas.drawLine(
        Offset(0, y + offset),
        Offset(rect.width, y + offset * 0.5),
        grainPaint,
      );
    }
  }

  void _drawBeveledFrame(Canvas canvas, Rect rect) {
    // Outer bevel (highlight)
    final outerBevel = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF8D6E63).withOpacity(0.4),
          Colors.transparent,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(22)),
      outerBevel,
    );

    // Inner bevel (shadow)
    final innerBevel = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: [
          Colors.black.withOpacity(0.3),
          Colors.transparent,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(6), const Radius.circular(20)),
      innerBevel,
    );
  }

  void _drawWoodGrain(Canvas canvas, Size size, double cell) {
    final grainPaint = Paint()
      ..color = const Color(0xFF2D1F17).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (var i = 0; i <= sizeN; i++) {
      final p = i * cell;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), grainPaint);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), grainPaint);
    }
  }

  void _drawCarvedPit(Canvas canvas, Offset center, double cell, int idx) {
    final pitSize = cell * 0.72;
    final pitRect = Rect.fromCenter(center: center, width: pitSize, height: pitSize);
    final pitRRect = RRect.fromRectAndRadius(pitRect, Radius.circular(pitSize * 0.5));

    // Deep shadow (carved effect)
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withOpacity(0.6),
          Colors.black.withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(pitRect);
    
    canvas.drawRRect(pitRRect, shadowPaint);

    // Inner pit gradient
    final pitPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
        colors: [
          const Color(0xFF2D1F17), // Dark center
          const Color(0xFF3E2723), // Medium edge
        ],
      ).createShader(pitRect);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        pitRect.deflate(2),
        Radius.circular(pitSize * 0.5),
      ),
      pitPaint,
    );

    // Subtle highlight on edge
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF8D6E63).withOpacity(0.2),
          Colors.transparent,
        ],
      ).createShader(pitRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        pitRect.deflate(1),
        Radius.circular(pitSize * 0.5),
      ),
      highlightPaint,
    );
  }

  void _drawAiTrail(Canvas canvas, double cell) {
    final from = _cellCenter(aiFromCell!, cell);
    final to = _cellCenter(aiToCell!, cell);
    
    final trail = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFFFB300).withOpacity(0.6),
          const Color(0xFFFFD54F).withOpacity(0.6),
        ],
      ).createShader(Rect.fromPoints(from, to))
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * (0.1 + 0.03 * pulse)
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(from, to, trail);

    // Glow effect
    final glow = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFFFB300).withOpacity(0.3),
          const Color(0xFFFFD54F).withOpacity(0.3),
        ],
      ).createShader(Rect.fromPoints(from, to))
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * (0.15 + 0.05 * pulse)
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    canvas.drawLine(from, to, glow);
  }

  void _drawHighlight(Canvas canvas, Offset center, double cell, Color color) {
    final size = cell * 0.85;
    final rect = Rect.fromCenter(center: center, width: size, height: size);
    
    // Outer glow
    final glow = Paint()
      ..color = color.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    
    canvas.drawCircle(center, size * 0.5, glow);

    // Inner ring
    final ring = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawCircle(center, size * 0.4, ring);
  }

  void _drawSelection(Canvas canvas, Offset center, double cell) {
    final size = cell * 0.9;
    
    // Pulsing glow
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withOpacity(0.4),
          const Color(0xFFFFB300).withOpacity(0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(center: center, width: size, height: size))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    
    canvas.drawCircle(center, size * 0.6, glow);

    // Selection ring
    final ring = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    canvas.drawCircle(center, size * 0.45, ring);
  }

  void _drawCaptureGlow(Canvas canvas, Offset center, double cell, double pulse) {
    final size = cell * (0.9 + 0.1 * pulse);
    
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF5252).withOpacity(0.6),
          const Color(0xFFFF1744).withOpacity(0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(center: center, width: size, height: size))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    
    canvas.drawCircle(center, size * 0.5, glow);
  }

  Offset _cellCenter(int idx, double cell) {
    final r = idx ~/ sizeN;
    final c = idx % sizeN;
    return Offset((c + 0.5) * cell, (r + 0.5) * cell);
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}

int? hitTestCell({required Offset localPos, required Size boardSize, required int n}) {
  if (localPos.dx < 0 || localPos.dy < 0 || localPos.dx > boardSize.width || localPos.dy > boardSize.height) return null;
  final cell = boardSize.width / n;
  final c = (localPos.dx / cell).floor();
  final r = (localPos.dy / cell).floor();
  if (r < 0 || c < 0 || r >= n || c >= n) return null;
  return r * n + c;
}
