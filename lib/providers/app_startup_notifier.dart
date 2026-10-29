import 'package:flutter/foundation.dart';

/// Coordina el arranque: si la intro terminó y si la primera pantalla
/// después del splash debe entrar con el revelado circular.
class AppStartupNotifier extends ChangeNotifier {
  AppStartupNotifier({this.isFirstLaunch = true, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Tiempo durante el cual las reconstrucciones de la primera ruta
  /// siguen usando la transición de revelado (dura ~1 s).
  static const Duration revealWindow = Duration(milliseconds: 1500);

  /// `true` si es la primera vez que se abre la app (intro completa).
  final bool isFirstLaunch;
  final DateTime Function() _clock;

  bool _introCompleted = false;
  DateTime? _revealStartedAt;

  bool get introCompleted => _introCompleted;

  void completeIntro() {
    if (_introCompleted) return;
    _introCompleted = true;
    notifyListeners();
  }

  /// `true` solo para la transición splash → primera pantalla.
  bool shouldUseReveal() {
    if (!_introCompleted) return false;
    final startedAt = _revealStartedAt ??= _clock();
    return _clock().difference(startedAt) < revealWindow;
  }
}
