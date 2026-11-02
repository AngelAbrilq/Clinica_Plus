import 'package:flutter/foundation.dart';

import '../data/repositories/catalog_admin_repository.dart';
import '../models/catalog_usage.dart';
import '../models/site.dart';
import '../models/specialty.dart';
import '../utils/app_exception.dart';

/// Estado del módulo "Sedes y especialidades".
class CatalogAdminProvider extends ChangeNotifier {
  CatalogAdminProvider(this._repository);

  final CatalogAdminRepository _repository;

  List<Site> _sites = const [];
  List<Specialty> _specialties = const [];
  CatalogOverview _overview = CatalogOverview.empty;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<Site> get sites => _sites;
  List<Specialty> get specialties => _specialties;
  CatalogOverview get overview => _overview;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  /// Sedes y especialidades activas primero, luego inactivas.
  List<Site> get sortedSites => [..._sites]
    ..sort((a, b) => a.isActive == b.isActive ? a.name.compareTo(b.name) : (a.isActive ? -1 : 1));

  List<Specialty> get sortedSpecialties => [..._specialties]
    ..sort((a, b) => a.isActive == b.isActive ? a.name.compareTo(b.name) : (a.isActive ? -1 : 1));

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _reload();
    } on AppException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveSite(SiteDraft draft, {int? id}) =>
      _save(() => _repository.saveSite(draft, id: id));

  Future<bool> saveSpecialty(SpecialtyDraft draft, {int? id}) =>
      _save(() => _repository.saveSpecialty(draft, id: id));

  Future<bool> setSiteActive(Site site, {required bool isActive}) =>
      _save(() => _repository.setSiteActive(site.id, isActive: isActive));

  Future<bool> setSpecialtyActive(Specialty specialty, {required bool isActive}) =>
      _save(() => _repository.setSpecialtyActive(specialty.id, isActive: isActive));

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _reload() async {
    final results = await Future.wait([
      _repository.fetchAllSites(),
      _repository.fetchAllSpecialties(),
      _repository.fetchOverview(),
    ]);
    _sites = results[0] as List<Site>;
    _specialties = results[1] as List<Specialty>;
    _overview = results[2] as CatalogOverview;
  }

  Future<bool> _save(Future<void> Function() action) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      await _reload();
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
