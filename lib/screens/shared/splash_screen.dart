import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../config/constants/app_constants.dart';
import '../../providers/app_startup_notifier.dart';
import '../../widgets/app_logo.dart';
import 'widgets/ecg_painter.dart';
import 'widgets/pulse_rings_painter.dart';

/// Intro animada: resplandor de fondo → logo con rebote → ondas de pulso →
/// electrocardiograma neón → título letra por letra → eslogan.
/// Al terminar avisa a [AppStartupNotifier] y el router continúa.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Color _navy = Color(0xFF071226);
  static const Color _blue = Color(0xFF1565C0);
  static const Color _cyan = Color(0xFF4FC3F7);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  // Cada elemento usa un tramo (Interval) de la misma línea de tiempo.
  late final Animation<double> _glow = _segment(0.00, 0.40, Curves.easeOut);
  late final Animation<double> _logoScale = _segment(
    0.05,
    0.45,
    Curves.elasticOut,
  );
  late final Animation<double> _ecg = _segment(
    0.30,
    0.78,
    Curves.easeInOutCubic,
  );
  late final Animation<double> _title = _segment(0.50, 0.88, Curves.linear);
  late final Animation<double> _tagline = _segment(0.74, 1.00, Curves.easeOut);

  bool _started = false;

  Animation<double> _segment(double begin, double end, Curve curve) =>
      CurvedAnimation(
        parent: _intro,
        curve: Interval(begin, end, curve: curve),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      // Accesibilidad: sin animaciones, mostrar todo de inmediato.
      _intro.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _completeIntro());
      return;
    }
    _pulse.repeat();
    _intro.forward().whenComplete(_completeIntro);
  }

  void _completeIntro() {
    if (mounted) context.read<AppStartupNotifier>().completeIntro();
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final ecgWidth = math.min(320.0, screenWidth - 48);

    return Scaffold(
      backgroundColor: _navy,
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _pulse]),
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.25),
                  radius: 0.5 + 0.7 * _glow.value,
                  colors: [
                    Color.lerp(_navy, _blue, _glow.value * 0.85)!,
                    _navy,
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 230,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size.square(230),
                            painter: PulseRingsPainter(
                              progress: _pulse.value,
                              opacity: _glow.value,
                              color: _cyan,
                            ),
                          ),
                          Transform.scale(
                            scale: _logoScale.value,
                            child: const AppLogo(size: 108),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: ecgWidth,
                      height: 72,
                      child: CustomPaint(
                        painter: EcgPainter(progress: _ecg.value, color: _cyan),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _LetterByLetterTitle(
                      text: AppConstants.appName,
                      progress: _title.value,
                    ),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: _tagline.value,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - _tagline.value)),
                        child: const Text(
                          'Tu salud, a tiempo',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Si la sesión tarda más que la intro, indicador discreto.
            if (_intro.isCompleted)
              Positioned(
                left: 0,
                right: 0,
                bottom: 56,
                child: Center(
                  child: SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(2),
                      color: _cyan,
                      backgroundColor: Colors.white12,
                      semanticsLabel: 'Cargando',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Título que aparece letra por letra subiendo suavemente.
class _LetterByLetterTitle extends StatelessWidget {
  const _LetterByLetterTitle({required this.text, required this.progress});

  final String text;
  final double progress;

  /// Cuántas letras "se solapan" en su animación (más = más fluido).
  static const int _overlap = 4;

  @override
  Widget build(BuildContext context) {
    final letters = text.characters.toList();
    final totalSteps = letters.length + _overlap;

    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < letters.length; index++)
            Builder(
              builder: (_) {
                final letterProgress =
                    ((progress * totalSteps - index) / _overlap).clamp(
                      0.0,
                      1.0,
                    );
                final eased = Curves.easeOutBack.transform(letterProgress);
                return Opacity(
                  opacity: letterProgress,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - eased)),
                    child: Text(
                      letters[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
