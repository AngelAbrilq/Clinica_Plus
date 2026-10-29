import 'package:flutter/foundation.dart';

/// Indica si la animación de entrada (splash) ya terminó.
/// El router no sale del splash hasta que la intro y la sesión estén listas.
class AppStartupNotifier extends ChangeNotifier {
  bool _introCompleted = false;

  bool get introCompleted => _introCompleted;

  void completeIntro() {
    if (_introCompleted) return;
    _introCompleted = true;
    notifyListeners();
  }
}
