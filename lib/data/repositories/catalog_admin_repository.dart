import '../../models/catalog_usage.dart';
import '../../models/site.dart';
import '../../models/specialty.dart';

/// Administración de sedes y especialidades. Nunca se borran: se
/// desactivan, para no romper citas e historias que las referencian.
abstract interface class CatalogAdminRepository {
  /// Todas, incluidas las inactivas.
  Future<List<Site>> fetchAllSites();

  Future<List<Specialty>> fetchAllSpecialties();

  Future<CatalogOverview> fetchOverview();

  /// Crea si [id] es null; si no, actualiza.
  Future<void> saveSite(SiteDraft draft, {int? id});

  Future<void> saveSpecialty(SpecialtyDraft draft, {int? id});

  Future<void> setSiteActive(int id, {required bool isActive});

  Future<void> setSpecialtyActive(int id, {required bool isActive});
}
