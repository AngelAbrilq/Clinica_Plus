import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Recorta el contenido en un círculo que crece desde [center]
/// hasta cubrir toda la pantalla ([fraction] de 0 a 1).
class CircularRevealClipper extends CustomClipper<Path> {
  const CircularRevealClipper({
    required this.fraction,
    this.center = const Alignment(0, -0.12),
  });

  final double fraction;
  final Alignment center;

  @override
  Path getClip(Size size) {
    final origin = center.alongSize(size);
    // Distancia a la esquina más lejana = radio que cubre toda la pantalla.
    final maxRadius = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((corner) => (corner - origin).distance).reduce(math.max);
    return Path()
      ..addOval(Rect.fromCircle(center: origin, radius: maxRadius * fraction));
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) =>
      oldClipper.fraction != fraction || oldClipper.center != center;
}
