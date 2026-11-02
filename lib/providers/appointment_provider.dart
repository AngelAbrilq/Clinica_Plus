import 'package:flutter/foundation.dart';

import '../data/repositories/appointment_repository.dart';
import '../models/available_slot.dart';
import '../models/patient_appointment.dart';
import '../models/site.dart';
import '../models/specialty.dart';
import '../utils/app_exception.dart';

/// Estado del agendamiento y de las citas del paciente.
class AppointmentProvider extends ChangeNotifier {
  AppointmentProvider(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppointmentRepository _repository;
  final DateTime Function() _clock;

  List<Specialty> _specialties = const [];
  List<Site> _sites = const [];
  List<AvailableSlot> _slots = const [];
  List<PatientAppointment> _appointments = const [];
  bool _isLoadingCatalogs = false;
  bool _isLoadingSlots = false;
  bool _isLoadingAppointments = false;
  bool _isSaving = false;
  String? _errorMessage;

  /// Cada consulta de horas lleva un número; si el usuario cambia de fecha
  /// rápido, se descartan respuestas viejas que lleguen tarde.
  int _slotsRequestId = 0;

  List<Specialty> get specialties => _specialties;
  List<Site> get sites => _sites;
  List<AvailableSlot> get slots => _slots;
  List<PatientAppointment> get appointments => _appointments;
  bool get isLoadingCatalogs => _isLoadingCatalogs;
  bool get isLoadingSlots => _isLoadingSlots;
  bool get isLoadingAppointments => _isLoadingAppointments;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  /// Próximas primero (la más cercana arriba).
  List<PatientAppointment> get upcoming {
    final now = _clock();
    return _appointments.where((item) => item.isUpcoming(now)).toList()
      ..sort((a, b) => a.startsAt!.compareTo(b.startsAt!));
  }

  /// Historial: todo lo que no es próximo (más reciente arriba).
  List<PatientAppointment> get history {
    final now = _clock();
    return _appointments.where((item) => !item.isUpcoming(now)).toList();
  }

  PatientAppointment? appointmentById(int id) {
    for (final appointment in _appointments) {
      if (appointment.id == id) return appointment;
    }
    return null;
  }

  bool canCancel(PatientAppointment appointment) =>
      appointment.canCancel(_clock());

  Future<void> loadCatalogs() async {
    if (_specialties.isNotEmpty && _sites.isNotEmpty) return;
    _isLoadingCatalogs = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.fetchSpecialties(),
        _repository.fetchSites(),
      ]);
      _specialties = results[0] as List<Specialty>;
      _sites = results[1] as List<Site>;
    } on AppException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoadingCatalogs = false;
      notifyListeners();
    }
  }

  Future<void> loadSlots({
    required int specialtyId,
    required int siteId,
    required DateTime date,
  }) async {
    final requestId = ++_slotsRequestId;
    _isLoadingSlots = true;
    _slots = const [];
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.fetchAvailableSlots(
        specialtyId: specialtyId,
        siteId: siteId,
        date: date,
      );
      if (requestId != _slotsRequestId) return; // respuesta vieja: se ignora
      _slots = result;
    } on AppException catch (error) {
      if (requestId != _slotsRequestId) return;
      _errorMessage = error.message;
    } finally {
      if (requestId == _slotsRequestId) {
        _isLoadingSlots = false;
        notifyListeners();
      }
    }
  }

  void clearSlots() {
    _slotsRequestId++;
    _slots = const [];
    _isLoadingSlots = false;
    notifyListeners();
  }

  Future<void> loadMyAppointments() async {
    _isLoadingAppointments = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _appointments = await _repository.fetchMyAppointments();
    } on AppException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoadingAppointments = false;
      notifyListeners();
    }
  }

  /// Agenda y devuelve el id de la cita, o `null` si falló.
  Future<int?> book({
    required int specialtyId,
    required int siteId,
    required AvailableSlot slot,
    String? symptoms,
  }) => _save(() async {
    final trimmed = symptoms?.trim();
    final appointmentId = await _repository.bookAppointment(
      specialtyId: specialtyId,
      siteId: siteId,
      startsAt: slot.startsAt,
      symptoms: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
    _appointments = await _repository.fetchMyAppointments();
    return appointmentId;
  });

  Future<bool> cancel(PatientAppointment appointment, {String? reason}) async {
    final result = await _save(() async {
      await _repository.cancelAppointment(
        appointmentId: appointment.id,
        reason: reason,
      );
      _appointments = await _repository.fetchMyAppointments();
      return true;
    });
    return result ?? false;
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<T?> _save<T>(Future<T> Function() action) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await action();
    } on AppException catch (error) {
      _errorMessage = error.message;
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
