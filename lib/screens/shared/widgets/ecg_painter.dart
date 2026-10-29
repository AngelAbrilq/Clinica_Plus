import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// Dibuja un electrocardiograma progresivo con brillo neón.
/// [progress] va de 0 (nada dibujado) a 1 (trazo completo).
class EcgPainter extends CustomPainter {
  const EcgPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  /// Puntos normalizados (0..1) de un latido: línea base, onda P,
  /// complejo QRS (pico) y onda T.
  static const List<Offset> _beat = [
    Offset(0.00, 0.60),
    Offset(0.22, 0.60),
    Offset(0.27, 0.50),
    Offset(0.32, 0.60),
    Offset(0.38, 0.60),
    Offset(0.42, 0.72),
    Offset(0.47, 0.04),
    Offset(0.52, 0.96),
    Offset(0.56, 0.60),
    Offset(0.64, 0.60),
    Offset(0.70, 0.42),
    Offset(0.77, 0.60),
    Offset(1.00, 0.60),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final path = Path()
      ..moveTo(_beat.first.dx * size.width, _beat.first.dy * size.height);
    for (final point in _beat.skip(1)) {
      path.lineTo(point.dx * size.width, point.dy * size.height);
    }

    final ui.PathMetric metric = path.computeMetrics().first;
    final drawnLength = metric.length * progress.clamp(0.0, 1.0);
    final visiblePath = metric.extractPath(0, drawnLength);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas
      ..drawPath(visiblePath, glowPaint)
      ..drawPath(visiblePath, linePaint);

    // Punto brillante en la "cabeza" del trazo.
    final tangent = metric.getTangentForOffset(drawnLength);
    if (tangent != null && progress < 1) {
      canvas
        ..drawCircle(
          tangent.position,
          9,
          Paint()
            ..color = color.withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        )
        ..drawCircle(tangent.position, 3.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(EcgPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
