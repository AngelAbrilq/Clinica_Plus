import 'package:flutter/foundation.dart';

import '../data/repositories/doctor_repository.dart';
import '../models/doctor_appointment.dart';
import '../models/medical_record.dart';
import '../utils/app_exception.dart';

/// Estado del portal médico: agenda del día y consulta abierta.
class DoctorProvider extends ChangeNotifier {
  DoctorProvider(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      _date = _dateOnly((clock ?? DateTime.now)());

  final DoctorRepository _repository;
  final DateTime Function() _clock;

  DateTime _date;
  List<DoctorAppointment> _agenda = const [];
  ConsultationDetail? _consultation;
  List<MedicalRecord>? _history;
  bool _isLoadingAgenda = false;
  bool _isLoadingConsultation = false;
  bool _isLoadingHistory = false;
  bool _isSaving = false;
  String? _errorMessage;

  DateTime get date => _date;
  DateTime get now => _clock();
  bool get isToday => _dateOnly(_clock()) == _date;
  List<DoctorAppointment> get agenda => _agenda;
  ConsultationDetail? get consultation => _consultation;

  /// `null` = aún no se ha consultado (se pide bajo demanda y queda auditado).
  List<MedicalRecord>? get history => _history;
  bool get isLoadingAgenda => _isLoadingAgenda;
  bool get isLoadingConsultation => _isLoadingConsultation;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  List<DoctorAppointment> byGroup(DoctorAgendaGroup group) =>
      _agenda.where((item) => item.group == group).toList();

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> loadAgenda() async {
    _isLoadingAgenda = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _agenda = await _repository.fetchAgenda(_date);
    } on AppException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoadingAgenda = false;
      notifyListeners();
    }
  }

  Future<void> shiftDate(int days) {
    _date = _dateOnly(_date.add(Duration(days: days)));
    return loadAgenda();
  }

  Future<void> goToToday() {
    _date = _dateOnly(_clock());
    return loadAgenda();
  }

  Future<void> openConsultation(int appointmentId) async {
    _consultation = null;
    _history = null;
    _isLoadingConsultation = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _consultation = await _repository.fetchConsultation(appointmentId);
    } on AppException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoadingConsultation = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    final consultation = _consultation;
    if (consultation == null) return;
    _isLoadingHistory = true;
    notifyListeners();
    try {
      _history = await _repository.fetchPatientHistory(consultation.id);
    } on AppException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<bool> startConsultation() =>
      _save((id) => _repository.startConsultation(id));

  Future<bool> completeConsultation(ConsultationNote note) =>
      _save((id) => _repository.completeConsultation(id, note));

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Ejecuta la acción sobre la consulta abierta y recarga consulta + agenda.
  Future<bool> _save(Future<Object?> Function(int appointmentId) action) async {
    final consultation = _consultation;
    if (consultation == null) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action(consultation.id);
      _consultation = await _repository.fetchConsultation(consultation.id);
      _agenda = await _repository.fetchAgenda(_date);
      return true;
    } on AppException catch (error) {
      _errorMessage = error.message;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}

/// Historia clínica del paciente autenticado.
class MedicalRecordsProvider extends ChangeNotifier {
  MedicalRecordsProvider(this._repository);

  final MedicalRecordsRepository _repository;

  List<MedicalRecord> _records = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MedicalRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _records = await _repository.fetchMyRecords();
    } on AppException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
