import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatelessWidget {
  const ConfettiOverlay({super.key, required this.progress, this.visible = false});

  final Animation<double> progress;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, child) {
          return CustomPaint(
            painter: _ConfettiPainter(progress.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final pieces = 120;
    for (var i = 0; i < pieces; i++) {
      final rand = Random(i * 997);
      final x = rand.nextDouble() * size.width;
      final drift = (rand.nextDouble() - 0.5) * 80;
      final y = (-100 + t * (size.height + 200)) + rand.nextDouble() * 120;
      final w = 6 + rand.nextDouble() * 6;
      final h = 10 + rand.nextDouble() * 8;
      final rot = rand.nextDouble() * pi;
      final color = _palette[i % _palette.length].withOpacity(0.9);

      canvas.save();
      canvas.translate(x + drift * sin(t * 6 + i), y);
      canvas.rotate(rot + t * 2);
      final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
      final paint = Paint()..color = color;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.t != t;
}

const _palette = [
  Color(0xFFFFC107),
  Color(0xFF40C4FF),
  Color(0xFFFF8A65),
  Color(0xFF7CFF6B),
  Color(0xFFE57373),
  Color(0xFFB39DDB),
];
