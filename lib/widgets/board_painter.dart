import 'dart:math';
import 'package:flutter/material.dart';

class BoardPainter extends CustomPainter {
  BoardPainter({required this.sizeN, required this.highlightCells, required this.selectedCell, required this.captureMode});

  final int sizeN;
  final Set<int> highlightCells;
  final int? selectedCell;
  final bool captureMode;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Wood-like background
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [Color(0xFF5A3A28), Color(0xFF3E271B), Color(0xFF2B1C14)],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      bg,
    );

    // Inner frame
    final frame = Paint()
      ..color = const Color(0xFF1A120D).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(6), const Radius.circular(20)),
      frame,
    );

    // Grid
    final cell = size.width / sizeN;

    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 0; i <= sizeN; i++) {
      final p = i * cell;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), gridPaint);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), gridPaint);
    }

    // Pits
    for (var r = 0; r < sizeN; r++) {
      for (var c = 0; c < sizeN; c++) {
        final cx = (c + 0.5) * cell;
        final cy = (r + 0.5) * cell;
        final radius = cell * 0.32;

        final pitRect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

        final shadow = Paint()
          ..shader = RadialGradient(
            colors: [Colors.black.withOpacity(0.55), Colors.transparent],
            stops: const [0.0, 1.0],
          ).createShader(pitRect);
        canvas.drawCircle(Offset(cx, cy + cell * 0.06), radius, shadow);

        final pit = Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFF2A1A12),
              const Color(0xFF3A2418),
              const Color(0xFF553624),
            ],
            stops: const [0.0, 0.65, 1.0],
          ).createShader(pitRect);
        canvas.drawCircle(Offset(cx, cy), radius * 0.95, pit);

        // highlight
        final idx = r * sizeN + c;
        if (highlightCells.contains(idx)) {
          final hl = Paint()
            ..color = (captureMode ? const Color(0xFFE53935) : const Color(0xFF00E5FF)).withOpacity(0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3;
          canvas.drawCircle(Offset(cx, cy), radius * 0.98, hl);
        }

        // selected
        if (selectedCell == idx) {
          final sel = Paint()
            ..color = const Color(0xFFFFD54F).withOpacity(0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4;
          canvas.drawCircle(Offset(cx, cy), radius * 1.05, sel);
        }
      }
    }

    // subtle gloss
    final gloss = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(0.10), Colors.transparent],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      gloss,
    );
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.sizeN != sizeN ||
        oldDelegate.highlightCells != highlightCells ||
        oldDelegate.selectedCell != selectedCell ||
        oldDelegate.captureMode != captureMode;
  }
}

int? hitTestCell({required Offset localPos, required Size boardSize, required int n}) {
  if (localPos.dx < 0 || localPos.dy < 0 || localPos.dx > boardSize.width || localPos.dy > boardSize.height) return null;
  final cell = boardSize.width / n;
  final c = (localPos.dx / cell).floor();
  final r = (localPos.dy / cell).floor();
  if (r < 0 || c < 0 || r >= n || c >= n) return null;
  return r * n + c;
}
