import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../config/constants/app_constants.dart';
import '../../data/local/app_preferences.dart';
import '../../providers/app_startup_notifier.dart';
import '../../widgets/app_logo.dart';
import 'widgets/aurora_painter.dart';
import 'widgets/ecg_painter.dart';
import 'widgets/pulse_rings_painter.dart';

/// Intro cinematográfica:
///  1. Aparece una aurora de luz con partículas.
///  2. Se dibujan dos latidos (el celular vibra en cada pico).
///  3. El trazo se contrae hacia el centro, destello, y nace el logo.
///  4. Brillo que recorre el logo + ondas de pulso.
///  5. Título letra por letra y eslogan.
/// Al terminar, el router abre la siguiente pantalla con revelado circular.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Color _navy = Color(0xFF050B1A);
  static const Color _cyan = Color(0xFF4FC3F7);
  static const Duration _fullIntro = Duration(milliseconds: 4600);
  static const Duration _quickIntro = Duration(milliseconds: 2400);
  static const Size _ecgReferenceSize = Size(360, 96);

  late final AnimationController _intro = AnimationController(vsync: this);
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );

  // Línea de tiempo (fracciones de la duración total).
  late final Animation<double> _aurora = _segment(0.00, 0.18, Curves.easeOut);
  late final Animation<double> _ecgDraw = _segment(
    0.06,
    0.52,
    Curves.easeInOutSine,
  );
  late final Animation<double> _ecgCollapse = _segment(
    0.52,
    0.63,
    Curves.easeInCubic,
  );
  late final Animation<double> _flash = _segment(0.58, 0.72, Curves.easeOut);
  late final Animation<double> _logoScale = _segment(
    0.58,
    0.80,
    Curves.elasticOut,
  );
  late final Animation<double> _rings = _segment(0.64, 0.78, Curves.easeOut);
  late final Animation<double> _shine = _segment(0.74, 0.90, Curves.easeInOut);
  late final Animation<double> _title = _segment(0.70, 0.93, Curves.linear);
  late final Animation<double> _tagline = _segment(0.85, 1.00, Curves.easeOut);
  late final Animation<double> _skipHint = _segment(0.20, 0.35, Curves.easeOut);

  late final List<double> _peakFractions = EcgPath.peakFractions(
    _ecgReferenceSize,
  );
  final Set<int> _firedBeats = {};
  bool _flashFired = false;
  bool _started = false;
  bool _hapticsEnabled = true;

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

    final startup = context.read<AppStartupNotifier>();
    if (MediaQuery.disableAnimationsOf(context)) {
      // Accesibilidad: sin movimiento ni vibraciones.
      _hapticsEnabled = false;
      _intro.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _finishIntro());
      return;
    }

    // Se escucha el estado (no el Future de forward) porque al saltar la
    // intro con animateTo() el forward original se cancela.
    _intro
      ..duration = startup.isFirstLaunch ? _fullIntro : _quickIntro
      ..addListener(_syncHaptics)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finishIntro();
      });
    _ambient.repeat();
    _pulse.repeat();
    _intro.forward();
  }

  /// Vibra cuando el trazo pasa por cada pico y en el destello del logo.
  void _syncHaptics() {
    if (!_hapticsEnabled) return;
    for (var beat = 0; beat < _peakFractions.length; beat++) {
      if (_ecgDraw.value >= _peakFractions[beat] && _firedBeats.add(beat)) {
        HapticFeedback.heavyImpact();
      }
    }
    if (!_flashFired && _flash.value > 0) {
      _flashFired = true;
      HapticFeedback.mediumImpact();
    }
  }

  void _skip() {
    if (_intro.isAnimating) {
      _hapticsEnabled = false;
      _intro.animateTo(
        1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  void _finishIntro() {
    if (!mounted) return;
    final startup = context.read<AppStartupNotifier>();
    if (startup.isFirstLaunch) context.read<AppPreferences>().markIntroSeen();
    startup.completeIntro();
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final ecgWidth = math.min(_ecgReferenceSize.width, screenWidth - 32);

    return Scaffold(
      backgroundColor: _navy,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: AnimatedBuilder(
          animation: Listenable.merge([_intro, _pulse, _ambient]),
          builder: (context, _) => Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: AuroraPainter(
                  time: _ambient.value,
                  intensity: _aurora.value,
                ),
              ),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            CustomPaint(
                              size: const Size.square(240),
                              painter: PulseRingsPainter(
                                progress: _pulse.value,
                                opacity: _rings.value,
                                color: _cyan,
                              ),
                            ),
                            // El ECG es más ancho que esta caja: OverflowBox
                            // lo deja centrado sobre el logo.
                            OverflowBox(
                              maxWidth: ecgWidth,
                              maxHeight: _ecgReferenceSize.height,
                              child: CustomPaint(
                                size: Size(ecgWidth, _ecgReferenceSize.height),
                                painter: EcgPainter(
                                  progress: _ecgDraw.value,
                                  collapse: _ecgCollapse.value,
                                  color: _cyan,
                                ),
                              ),
                            ),
                            _Flash(progress: _flash.value),
                            Transform.scale(
                              scale: _logoScale.value,
                              child: _ShineSweep(
                                progress: _shine.value,
                                child: const AppLogo(size: 112),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
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
                              letterSpacing: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: Center(
                  child: _intro.isCompleted
                      ? SizedBox(
                          width: 120,
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            borderRadius: BorderRadius.circular(2),
                            color: _cyan,
                            backgroundColor: Colors.white12,
                            semanticsLabel: 'Cargando',
                          ),
                        )
                      : Opacity(
                          opacity: _skipHint.value * 0.6,
                          child: const Text(
                            'Toca para continuar',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Destello blanco que se expande cuando el latido "se convierte" en logo.
class _Flash extends StatelessWidget {
  const _Flash({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
    final size = 60 + 220 * progress;
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.85 * (1 - progress)),
              const Color(0xFF4FC3F7).withValues(alpha: 0.35 * (1 - progress)),
              Colors.transparent,
            ],
            stops: const [0, 0.45, 1],
          ),
        ),
      ),
    );
  }
}

/// Franja de luz diagonal que recorre el logo (efecto "brillo premium").
class _ShineSweep extends StatelessWidget {
  const _ShineSweep({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return child;
    final center = -0.4 + 1.8 * progress; // la franja cruza de izq. a der.
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.65),
          Colors.transparent,
        ],
        stops: [
          (center - 0.18).clamp(0.0, 1.0),
          center.clamp(0.0, 1.0),
          (center + 0.18).clamp(0.0, 1.0),
        ],
      ).createShader(bounds),
      child: child,
    );
  }
}

/// Título que aparece letra por letra subiendo con un leve rebote.
class _LetterByLetterTitle extends StatelessWidget {
  const _LetterByLetterTitle({required this.text, required this.progress});

  final String text;
  final double progress;
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
                    offset: Offset(0, 20 * (1 - eased)),
                    child: Text(
                      letters[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(color: Color(0x884FC3F7), blurRadius: 18),
                        ],
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
