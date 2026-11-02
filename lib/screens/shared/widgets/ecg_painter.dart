import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// Geometría del electrocardiograma: dos latidos. El segundo pico (R)
/// cae exactamente en el centro, donde luego "nace" el logo.
abstract final class EcgPath {
  static const double _baseline = 0.58;

  /// Picos R (x normalizada) de cada latido.
  static const List<double> peakXs = [0.24, 0.50];

  /// Puntos normalizados (0..1): línea base + ondas P, QRS y T por latido.
  static final List<Offset> points = _buildPoints();

  static List<Offset> _buildPoints() {
    final result = <Offset>[const Offset(0, _baseline)];
    for (final peak in peakXs) {
      result.addAll([
        Offset(peak - 0.115, _baseline),
        Offset(peak - 0.090, _baseline - 0.10), // onda P
        Offset(peak - 0.065, _baseline),
        Offset(peak - 0.030, _baseline),
        Offset(peak - 0.015, _baseline + 0.12), // Q
        Offset(peak, 0.02), // R (pico)
        Offset(peak + 0.020, 0.98), // S
        Offset(peak + 0.040, _baseline),
        Offset(peak + 0.080, _baseline),
        Offset(peak + 0.105, _baseline - 0.16), // onda T
        Offset(peak + 0.135, _baseline),
      ]);
    }
    result.add(const Offset(1, _baseline));
    return result;
  }

  static Path build(Size size) {
    final path = Path()
      ..moveTo(points.first.dx * size.width, points.first.dy * size.height);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx * size.width, point.dy * size.height);
    }
    return path;
  }

  /// Fracción del trazo (0..1) en la que se alcanza cada pico R.
  /// Sirve para sincronizar la vibración con el dibujo.
  static List<double> peakFractions(Size size) {
    final scaled = [
      for (final p in points) Offset(p.dx * size.width, p.dy * size.height),
    ];
    final cumulative = <double>[0];
    for (var i = 1; i < scaled.length; i++) {
      cumulative.add(cumulative.last + (scaled[i] - scaled[i - 1]).distance);
    }
    final total = cumulative.last;
    return [
      for (final peak in peakXs)
        cumulative[points.indexWhere((p) => p.dx == peak && p.dy < 0.1)] /
            total,
    ];
  }
}

/// Dibuja el ECG con brillo neón.
/// [progress]: cuánto del trazo está dibujado (0..1).
/// [collapse]: el trazo se contrae hacia el centro y desaparece (0..1),
/// efecto de "el latido se convierte en el logo".
class EcgPainter extends CustomPainter {
  const EcgPainter({
    required this.progress,
    required this.color,
    this.collapse = 0,
  });

  final double progress;
  final double collapse;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || collapse >= 1) return;

    final ui.PathMetric metric = EcgPath.build(size).computeMetrics().first;
    final drawnLength = metric.length * progress.clamp(0.0, 1.0);
    final visiblePath = metric.extractPath(0, drawnLength);
    final opacity = 1 - collapse;

    canvas.save();
    if (collapse > 0) {
      // Se comprime horizontalmente hacia el pico central.
      final centerX = size.width * EcgPath.peakXs.last;
      canvas
        ..translate(centerX, size.height / 2)
        ..scale(1 - collapse, 1 - collapse * 0.5)
        ..translate(-centerX, -size.height / 2);
    }

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.55 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final linePaint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas
      ..drawPath(visiblePath, glowPaint)
      ..drawPath(visiblePath, linePaint);

    final tangent = metric.getTangentForOffset(drawnLength);
    if (tangent != null && progress < 1) {
      canvas
        ..drawCircle(
          tangent.position,
          11,
          Paint()
            ..color = color.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
        )
        ..drawCircle(tangent.position, 4, Paint()..color = Colors.white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(EcgPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.collapse != collapse ||
      oldDelegate.color != color;
}
