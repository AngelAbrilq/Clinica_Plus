import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Entrada con desvanecido + deslizamiento. Usar [delay] para escalonar
/// varios elementos (efecto "stagger"). Respeta "reducir movimiento"
/// del sistema operativo (accesibilidad).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.offset = const Offset(0, 0.12),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Desplazamiento inicial relativo al tamaño del hijo (0.12 = 12 %).
  final Offset offset;

  /// Retardo para el elemento [index] de una lista (máx. [maxSteps] pasos
  /// para que listas largas no tarden demasiado).
  static Duration staggerDelay(
    int index, {
    int stepMs = 60,
    int maxSteps = 8,
  }) => Duration(milliseconds: stepMs * index.clamp(0, maxSteps));

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: widget.offset,
    end: Offset.zero,
  ).animate(_curve);

  Timer? _delayTimer;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _curve,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}
