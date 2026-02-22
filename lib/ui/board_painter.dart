import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

/// Premium wooden board with indented cells, grain, and a border glow.
class DaraBoardPainter extends CustomPainter {
  final int gridSize;
  final List<List<int>>? highlightedCells; // [x, y] positions to highlight

  DaraBoardPainter({required this.gridSize, this.highlightedCells});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Board surface ──────────────────────────────────────────────
    final boardPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(w, h),
        [const Color(0xFF6D4C41), const Color(0xFF4E342E), const Color(0xFF795548)],
        [0.0, 0.5, 1.0],
      );
    final roundRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h), const Radius.circular(16));
    canvas.drawRRect(roundRect, boardPaint);

    // ── Wood grain (diagonal lines) ─────────────────────────────────
    final grainPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (double i = -h; i < w + h; i += 18) {
      canvas.drawLine(Offset(i, 0), Offset(i + h, h), grainPaint);
    }

    // ── Cross-grain ─────────────────────────────────────────────────
    final grainPaint2 = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (double i = -w; i < w + h; i += 32) {
      canvas.drawLine(Offset(0, i), Offset(w, i + w * 0.3), grainPaint2);
    }

    // ── Board shine (top edge highlight) ───────────────────────────
    final shinePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, h * 0.2),
        [Colors.white.withOpacity(0.12), Colors.transparent],
      )
      ..style = PaintingStyle.fill;
    canvas.drawRRect(roundRect, shinePaint);

    // ── Cells ────────────────────────────────────────────────────────
    final cellSize = w / gridSize;
    final cellRadius = cellSize * 0.35;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final cx = x * cellSize + cellSize / 2;
        final cy = y * cellSize + cellSize / 2;

        // Check if highlighted (valid move target)
        bool isHl = highlightedCells?.any((c) => c[0] == x && c[1] == y) ?? false;

        // Outer shadow (depth)
        canvas.drawCircle(
          Offset(cx, cy + 2),
          cellRadius,
          Paint()
            ..color = Colors.black.withOpacity(0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );

        // Cell depression background
        canvas.drawCircle(
          Offset(cx, cy),
          cellRadius,
          Paint()
            ..color = isHl
                ? const Color(0xFFFF8A65).withOpacity(0.35)
                : Colors.black.withOpacity(0.28),
        );

        // Inner glow ring
        canvas.drawCircle(
          Offset(cx, cy),
          cellRadius,
          Paint()
            ..color = isHl
                ? const Color(0xFFFF7043).withOpacity(0.6)
                : Colors.white.withOpacity(0.08)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isHl ? 2.0 : 1.0,
        );

        // Top-left inner shine (light bounce)
        canvas.drawCircle(
          Offset(cx - cellRadius * 0.3, cy - cellRadius * 0.35),
          cellRadius * 0.25,
          Paint()..color = Colors.white.withOpacity(0.06),
        );
      }
    }

    // ── Border ──────────────────────────────────────────────────────
    canvas.drawRRect(
      roundRect,
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant DaraBoardPainter old) =>
      old.highlightedCells != highlightedCells;
}

/// Premium seed with 3D gradient, specular highlight, and optional selection ring.
class DaraSeedPainter extends CustomPainter {
  final Color color;
  final bool isSelected;
  final bool isCapturable;
  final String skinId;

  const DaraSeedPainter({
    required this.color,
    this.isSelected = false,
    this.isCapturable = false,
    this.skinId = 'classic',
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width / 2) * 0.78;
    final isLight = color.computeLuminance() > 0.5;

    // ── Drop shadow ─────────────────────────────────────────────────
    canvas.drawCircle(
      c + Offset(r * 0.08, r * 0.14),
      r * 1.05,
      Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // ── Main body gradient ──────────────────────────────────────────
    Color c1, c2, c3;
    if (skinId == 'gold') {
      c1 = const Color(0xFFFFD54F); c2 = const Color(0xFFFFA000); c3 = const Color(0xFF827717);
    } else if (skinId == 'ebony') {
      c1 = const Color(0xFF607D8B); c2 = const Color(0xFF263238); c3 = const Color(0xFF101010);
    } else {
      // Classic
      c1 = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF555555);
      c2 = isLight ? const Color(0xFFDDDDDD) : const Color(0xFF2A2A2A);
      c3 = isLight ? const Color(0xFFAAAAAA) : const Color(0xFF111111);
    }

    final bodyGrad = ui.Gradient.radial(
      c + Offset(-r * 0.25, -r * 0.3),
      r * 1.2,
      [c1, c2, c3],
      [0.0, 0.6, 1.0],
    );
    canvas.drawCircle(c, r, Paint()..shader = bodyGrad);

    // ── Specular ring (light bezel) ─────────────────────────────────
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = (isLight ? Colors.white : Colors.white).withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.06,
    );

    // ── Top-left bright specular highlight ─────────────────────────
    final specGrad = ui.Gradient.radial(
      c + Offset(-r * 0.35, -r * 0.38),
      r * 0.5,
      [Colors.white.withOpacity(isLight ? 0.55 : 0.3), Colors.transparent],
      [0.0, 1.0],
    );
    canvas.drawCircle(
      c + Offset(-r * 0.25, -r * 0.28),
      r * 0.42,
      Paint()..shader = specGrad,
    );

    // ── Bottom-right rim reflection ─────────────────────────────────
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.88),
      pi * 0.65,
      pi * 0.5,
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08,
    );

    // ── Capturable pulsing ring ─────────────────────────────────────
    if (isCapturable) {
      canvas.drawCircle(
        c,
        r + 5,
        Paint()
          ..color = Colors.redAccent.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // ── Selection ring ───────────────────────────────────────────────
    if (isSelected) {
      canvas.drawCircle(
        c,
        r + 5,
        Paint()
          ..color = const Color(0xFFFFB74D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.drawCircle(
        c,
        r + 9,
        Paint()
          ..color = const Color(0xFFFFB74D).withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DaraSeedPainter old) =>
      old.isSelected != isSelected || old.isCapturable != isCapturable;
}
