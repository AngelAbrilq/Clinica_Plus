import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

class _Blob {
  const _Blob(
    this.color,
    this.radius,
    this.orbitX,
    this.orbitY,
    this.phase,
    this.speed,
  );

  final Color color;
  final double radius; // relativo al lado mayor de la pantalla
  final double orbitX;
  final double orbitY;
  final double phase;
  final int speed; // entero → el ciclo empalma sin saltos
}

class _Particle {
  const _Particle(
    this.x,
    this.y,
    this.size,
    this.alpha,
    this.phase,
    this.speed,
  );

  final double x;
  final double y;
  final double size;
  final double alpha;
  final double phase;
  final int speed;
}

/// Fondo "aurora": manchas de luz que orbitan lentamente y partículas
/// que suben titilando. [time] es un ciclo 0..1 en bucle.
class AuroraPainter extends CustomPainter {
  AuroraPainter({required this.time, required this.intensity});

  final double time;

  /// 0..1: permite que el fondo aparezca gradualmente.
  final double intensity;

  static const List<_Blob> _blobs = [
    _Blob(Color(0xFF1565C0), 0.62, 0.28, 0.20, 0.00, 1),
    _Blob(Color(0xFF00B8D4), 0.48, 0.32, 0.26, 0.33, 1),
    _Blob(Color(0xFF5E35B1), 0.44, 0.24, 0.30, 0.66, 1),
    _Blob(Color(0xFF29B6F6), 0.30, 0.36, 0.18, 0.15, 2),
  ];

  static final List<_Particle> _particles = _generateParticles(46);

  static List<_Particle> _generateParticles(int count) {
    final random = math.Random(7); // semilla fija: mismo patrón siempre
    return List.generate(
      count,
      (_) => _Particle(
        random.nextDouble(),
        random.nextDouble(),
        0.6 + random.nextDouble() * 1.8,
        0.25 + random.nextDouble() * 0.6,
        random.nextDouble(),
        1 + random.nextInt(2),
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    final longestSide = math.max(size.width, size.height);

    for (final blob in _blobs) {
      final angle = 2 * math.pi * (time * blob.speed + blob.phase);
      final center = Offset(
        size.width * (0.5 + blob.orbitX * math.cos(angle)),
        size.height * (0.45 + blob.orbitY * math.sin(angle)),
      );
      final radius = blob.radius * longestSide;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            blob.color.withValues(alpha: 0.50 * intensity),
            blob.color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    for (final particle in _particles) {
      final y = (particle.y - time * particle.speed) % 1.0;
      final x =
          particle.x +
          0.012 * math.sin(2 * math.pi * (time * 2 + particle.phase));
      final twinkle =
          0.5 + 0.5 * math.sin(2 * math.pi * (time * 3 + particle.phase));
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particle.size,
        Paint()
          ..color = Colors.white.withValues(
            alpha: particle.alpha * twinkle * intensity,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(AuroraPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.intensity != intensity;
}
