import 'package:flutter/foundation.dart';

import '../data/repositories/reception_repository.dart';
import '../models/reception_appointment.dart';
import '../models/site.dart';
import '../utils/app_exception.dart';
import '../utils/check_in_code.dart';

/// Estado de la recepción: sede y día seleccionados, agenda y acciones.
class ReceptionProvider extends ChangeNotifier {
  ReceptionProvider(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      _date = _dateOnly((clock ?? DateTime.now)());

  final ReceptionRepository _repository;
  final DateTime Function() _clock;

  List<Site> _sites = const [];
  int? _siteId;
  DateTime _date;
  List<ReceptionAppointment> _agenda = const [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  int _agendaRequestId = 0;

  List<Site> get sites => _sites;
  int? get siteId => _siteId;
  DateTime get date => _date;
  List<ReceptionAppointment> get agenda => _agenda;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  DateTime get now => _clock();

  bool get isToday => _dateOnly(_clock()) == _date;

  List<ReceptionAppointment> byGroup(ReceptionGroup group) =>
      _agenda.where((item) => item.group == group).toList();

  int countOf(ReceptionGroup group) =>
      _agenda.where((item) => item.group == group).length;

  /// Carga sedes (una vez) y la agenda de la primera sede.
  Future<void> initialize() async {
    if (_sites.isEmpty) {
      try {
        _sites = await _repository.fetchSites();
        _siteId ??= _sites.isEmpty ? null : _sites.first.id;
      } on AppException catch (error) {
        _errorMessage = error.message;
        notifyListeners();
        return;
      }
    }
    await refresh();
  }

  Future<void> selectSite(int siteId) async {
    if (_siteId == siteId) return;
    _siteId = siteId;
    await refresh();
  }

  Future<void> shiftDate(int days) async {
    _date = _dateOnly(_date.add(Duration(days: days)));
    await refresh();
  }

  Future<void> goToToday() async {
    _date = _dateOnly(_clock());
    await refresh();
  }

  Future<void> refresh() async {
    final siteId = _siteId;
    if (siteId == null) return;
    final requestId = ++_agendaRequestId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final agenda = await _repository.fetchAgenda(siteId: siteId, date: _date);
      if (requestId != _agendaRequestId) return;
      _agenda = agenda;
    } on AppException catch (error) {
      if (requestId != _agendaRequestId) return;
      _errorMessage = error.message;
    } finally {
      if (requestId == _agendaRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Check-in desde el contenido leído del QR. Lanza [AppException] con
  /// un mensaje claro si el código no es válido o la cita no lo admite.
  Future<CheckInResult> checkInFromCode(String rawCode) {
    final token = CheckInCode.parse(rawCode);
    if (token == null) {
      return Future.error(
        const AppException('Este código no es de Clinica Plus.'),
      );
    }
    return _process(() => _repository.checkInByToken(token));
  }

  Future<CheckInResult> checkInById(int appointmentId) =>
      _process(() => _repository.checkInById(appointmentId));

  Future<void> markNoShow(int appointmentId) =>
      _process(() => _repository.markNoShow(appointmentId));

  /// Sin dependencia de Flutter UI: el provider es lógica pura y testeable.
  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Ejecuta la acción, recarga la agenda y propaga el error a la UI.
  Future<T> _process<T>(Future<T> Function() action) async {
    _isProcessing = true;
    notifyListeners();
    try {
      final result = await action();
      await refresh();
      return result;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
