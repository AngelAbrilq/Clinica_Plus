import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/patient_directory_repository.dart';
import '../models/doctor_patient.dart';
import '../models/medical_record.dart';
import '../utils/app_exception.dart';

/// Estado de "Mis pacientes": búsqueda con debounce e historia del paciente.
class DoctorPatientsProvider extends ChangeNotifier {
  DoctorPatientsProvider(
    this._repository, {
    this.debounce = const Duration(milliseconds: 350),
  });

  final PatientDirectoryRepository _repository;

  /// Espera tras la última tecla antes de consultar al servidor.
  final Duration debounce;

  List<DoctorPatient> _patients = const [];
  String _query = '';
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounceTimer;
  int _searchRequestId = 0;

  String? _chartPatientId;
  List<MedicalRecord>? _chart;
  bool _isLoadingChart = false;

  List<DoctorPatient> get patients => _patients;
  String get query => _query;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<MedicalRecord>? get chart => _chart;
  bool get isLoadingChart => _isLoadingChart;

  DoctorPatient? patientById(String id) {
    for (final patient in _patients) {
      if (patient.id == id) return patient;
    }
    return null;
  }

  /// Llamar desde el TextField en cada cambio: agrupa las teclas.
  void onQueryChanged(String value) {
    _query = value;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, search);
  }

  /// Busca de inmediato con la consulta actual.
  Future<void> search() async {
    _debounceTimer?.cancel();
    final requestId = ++_searchRequestId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.fetchMyPatients(search: _query);
      if (requestId != _searchRequestId) return; // llegó tarde: se descarta
      _patients = result;
    } on AppException catch (error) {
      if (requestId != _searchRequestId) return;
      _errorMessage = error.message;
    } finally {
      if (requestId == _searchRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> openChart(String patientId) async {
    _chartPatientId = patientId;
    _chart = null;
    _isLoadingChart = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final records = await _repository.fetchPatientChart(patientId);
      if (_chartPatientId != patientId) return; // se abrió otro paciente
      _chart = records;
    } on AppException catch (error) {
      if (_chartPatientId != patientId) return;
      _errorMessage = error.message;
    } finally {
      if (_chartPatientId == patientId) {
        _isLoadingChart = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
