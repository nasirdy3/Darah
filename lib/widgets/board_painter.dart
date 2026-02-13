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

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: skin.baseGradient,
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24)), bg);

    final frame = Paint()
      ..color = skin.frame.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(6), const Radius.circular(20)), frame);

    final cell = size.width / sizeN;
    final gridPaint = Paint()
      ..color = skin.grid.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 0; i <= sizeN; i++) {
      final p = i * cell;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), gridPaint);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), gridPaint);
    }

    if (aiFromCell != null && aiToCell != null) {
      final from = _cellCenter(aiFromCell!, cell);
      final to = _cellCenter(aiToCell!, cell);
      final trail = Paint()
        ..shader = LinearGradient(
          colors: [const Color(0xFFB2FF59).withOpacity(0.7), const Color(0xFF4DD0E1).withOpacity(0.7)],
        ).createShader(Rect.fromPoints(from, to))
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.08
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(from, to, trail);
    }

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
            colors: [skin.pitDark, skin.pitLight, skin.pitDark.withOpacity(0.8)],
            stops: const [0.0, 0.7, 1.0],
          ).createShader(pitRect);
        canvas.drawCircle(Offset(cx, cy), radius * 0.95, pit);

        final idx = r * sizeN + c;

        if (highlightCells.contains(idx)) {
          final hl = Paint()
            ..color = (captureMode ? skin.capture : skin.highlight).withOpacity(0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.2;
          canvas.drawCircle(Offset(cx, cy), radius * 0.98, hl);
        }

        if (hintCells.contains(idx)) {
          final hl = Paint()
            ..color = const Color(0xFF7DD9FF).withOpacity(0.65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.4;
          canvas.drawCircle(Offset(cx, cy), radius * 1.02, hl);
        }

        if (selectedCell == idx) {
          final sel = Paint()
            ..color = const Color(0xFFFFD54F).withOpacity(0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.2;
          canvas.drawCircle(Offset(cx, cy), radius * 1.08, sel);
        }

        if (aiFromCell == idx) {
          final ai = Paint()
            ..color = const Color(0xFFB2FF59).withOpacity(0.75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.4;
          canvas.drawCircle(Offset(cx, cy), radius * 1.1, ai);
        }

        if (aiToCell == idx) {
          final ai = Paint()
            ..color = const Color(0xFF4DD0E1).withOpacity(0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.6;
          canvas.drawCircle(Offset(cx, cy), radius * 1.12, ai);
        }

        if (aiCaptureCell == idx) {
          final ai = Paint()
            ..color = const Color(0xFFFF6F60).withOpacity(0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.2;
          canvas.drawCircle(Offset(cx, cy), radius * 1.14, ai);
        }
      }
    }

    final gloss = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(0.12), Colors.transparent],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24)), gloss);
  }

  Offset _cellCenter(int idx, double cell) {
    final r = idx ~/ sizeN;
    final c = idx % sizeN;
    return Offset((c + 0.5) * cell, (r + 0.5) * cell);
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.sizeN != sizeN ||
        oldDelegate.highlightCells != highlightCells ||
        oldDelegate.hintCells != hintCells ||
        oldDelegate.selectedCell != selectedCell ||
        oldDelegate.captureMode != captureMode ||
        oldDelegate.skin != skin ||
        oldDelegate.aiFromCell != aiFromCell ||
        oldDelegate.aiToCell != aiToCell ||
        oldDelegate.aiCaptureCell != aiCaptureCell;
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
