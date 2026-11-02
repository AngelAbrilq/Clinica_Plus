import 'package:flutter/foundation.dart';

import '../data/repositories/admin_repository.dart';
import '../models/doctor_schedule.dart';
import '../models/site.dart';
import '../models/specialty.dart';
import '../models/staff_member.dart';
import '../models/user_role.dart';
import '../utils/app_exception.dart';

/// Estado del panel de administración (personal, médicos y horarios).
class AdminProvider extends ChangeNotifier {
  AdminProvider(this._repository);

  final AdminRepository _repository;

  List<StaffMember> _staff = const [];
  List<Site> _sites = const [];
  List<Specialty> _specialties = const [];
  List<DoctorSchedule> _schedules = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<StaffMember> get staff => _staff;
  List<Site> get sites => _sites;
  List<Specialty> get specialties => _specialties;
  List<DoctorSchedule> get schedules => _schedules;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  List<StaffMember> get pending =>
      _staff.where((member) => member.isPending).toList();

  List<StaffMember> withRole(UserRole role) =>
      _staff.where((member) => member.role == role).toList();

  StaffMember? doctorById(int doctorId) {
    for (final member in _staff) {
      if (member.doctor?.id == doctorId) return member;
    }
    return null;
  }

  /// Carga personal y catálogos en paralelo.
  Future<void> loadStaff() => _load(() async {
    final results = await Future.wait([
      _repository.fetchStaff(),
      if (_sites.isEmpty) _repository.fetchSites(),
      if (_specialties.isEmpty) _repository.fetchSpecialties(),
    ]);
    _staff = results[0] as List<StaffMember>;
    var index = 1;
    if (_sites.isEmpty) _sites = results[index++] as List<Site>;
    if (_specialties.isEmpty) _specialties = results[index] as List<Specialty>;
  });

  Future<void> loadSchedules(int doctorId) => _load(() async {
    _schedules = const []; // evita mostrar horarios de otro médico
    _schedules = await _repository.fetchSchedules(doctorId);
    if (_sites.isEmpty) _sites = await _repository.fetchSites();
  });

  Future<bool> assignRole({required String userId, required UserRole role}) =>
      _save(() async {
        await _repository.assignRole(userId: userId, role: role);
        _staff = await _repository.fetchStaff();
      });

  Future<bool> registerDoctor({
    required String userId,
    required int specialtyId,
    required String licenseNumber,
  }) => _save(() async {
    await _repository.registerDoctor(
      userId: userId,
      specialtyId: specialtyId,
      licenseNumber: licenseNumber,
    );
    _staff = await _repository.fetchStaff();
  });

  Future<bool> addSchedule(NewDoctorSchedule schedule) => _save(() async {
    await _repository.addSchedule(schedule);
    _schedules = await _repository.fetchSchedules(schedule.doctorId);
  });

  Future<bool> deleteSchedule(DoctorSchedule schedule) => _save(() async {
    await _repository.deleteSchedule(schedule.id);
    _schedules = _schedules.where((item) => item.id != schedule.id).toList();
  });

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _load(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on AppException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Devuelve `true` si la operación se completó.
  Future<bool> _save(Future<void> Function() action) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
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
