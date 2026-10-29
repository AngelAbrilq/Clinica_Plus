import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// Ondas concéntricas que se expanden y desvanecen (efecto "latido").
class PulseRingsPainter extends CustomPainter {
  const PulseRingsPainter({
    required this.progress,
    required this.opacity,
    required this.color,
    this.ringCount = 3,
    this.minRadius = 56,
  });

  /// Fase del ciclo (0..1), normalmente un AnimationController en repeat().
  final double progress;

  /// Opacidad global (permite que las ondas aparezcan gradualmente).
  final double opacity;
  final Color color;
  final int ringCount;
  final double minRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final center = size.center(Offset.zero);
    final maxRadius = math.min(size.width, size.height) / 2;

    for (var ring = 0; ring < ringCount; ring++) {
      final phase = (progress + ring / ringCount) % 1.0;
      final radius = ui.lerpDouble(
        minRadius,
        maxRadius,
        Curves.easeOut.transform(phase),
      )!;
      final alpha = (1 - phase) * 0.5 * opacity;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(PulseRingsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.opacity != opacity;
}
