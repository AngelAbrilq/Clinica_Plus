import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/waiting_room_repository.dart';
import '../models/queue_status.dart';
import '../utils/app_exception.dart';

/// Sala de espera en vivo: tiempo real para la cita propia + sondeo
/// periódico para ver avanzar la fila (las citas ajenas no llegan por
/// Realtime gracias a la RLS).
class WaitingRoomProvider extends ChangeNotifier {
  WaitingRoomProvider(
    this._repository, {
    this.pollInterval = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final WaitingRoomRepository _repository;
  final Duration pollInterval;
  final DateTime Function() _clock;

  int? _appointmentId;
  QueueStatus? _status;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;
  bool _turnJustArrived = false;
  Timer? _pollTimer;
  StreamSubscription<void>? _realtime;

  QueueStatus? get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;
  DateTime get now => _clock();

  /// `true` una sola vez cuando el paciente pasa a "es tu turno".
  /// La pantalla lo consume para vibrar/animar.
  bool consumeTurnArrived() {
    final value = _turnJustArrived;
    _turnJustArrived = false;
    return value;
  }

  /// Empieza a seguir [appointmentId]. Llamar [stop] al salir de la pantalla.
  Future<void> start(int appointmentId) async {
    if (_appointmentId == appointmentId && _pollTimer != null) return;
    stop();
    _appointmentId = appointmentId;
    _status = null;
    _realtime = _repository.watchAppointment(appointmentId).listen((_) => refresh());
    _pollTimer = Timer.periodic(pollInterval, (_) => refresh());
    await refresh();
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _realtime?.cancel();
    _realtime = null;
    _appointmentId = null;
  }

  Future<void> refresh() async {
    final appointmentId = _appointmentId;
    if (appointmentId == null || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final next = await _repository.fetchQueueStatus(appointmentId);
      if (_appointmentId != appointmentId) return; // cambió de cita
      final wasYourTurn = _status?.isYourTurn ?? false;
      if (!wasYourTurn && next.isYourTurn) _turnJustArrived = true;
      _status = next;
      _errorMessage = null;
      _lastUpdated = _clock();
      // Cita terminada: ya no hace falta seguir consultando.
      if (next.isOver) {
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    } on AppException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
