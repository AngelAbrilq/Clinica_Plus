import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/catalog_usage.dart';
import '../../models/site.dart';
import '../../models/specialty.dart';
import '../../utils/app_exception.dart';
import '../services/supabase_error_mapper.dart';
import 'catalog_admin_repository.dart';

/// Escribe directo en las tablas: la RLS (`*_admin_write`) garantiza que
/// solo un admin pueda hacerlo.
class SupabaseCatalogAdminRepository implements CatalogAdminRepository {
  SupabaseCatalogAdminRepository(this._client);

  final SupabaseClient _client;

  static const Map<String, String> _duplicateName = {
    '23505': 'Ya existe un registro con ese nombre.',
    '23514': 'La duración debe estar entre 10 y 120 minutos.',
  };

  @override
  Future<List<Site>> fetchAllSites() => SupabaseErrorMapper.guard(() async {
    final rows = await _client.from('sites').select().order('name');
    return rows.map(Site.fromJson).toList();
  });

  @override
  Future<List<Specialty>> fetchAllSpecialties() => SupabaseErrorMapper.guard(() async {
    final rows = await _client.from('specialties').select().order('name');
    return rows.map(Specialty.fromJson).toList();
  });

  @override
  Future<CatalogOverview> fetchOverview() => SupabaseErrorMapper.guard(() async {
    final json = await _client.rpc<Map<String, dynamic>>('admin_catalog_overview');
    return CatalogOverview.fromJson(json);
  });

  @override
  Future<void> saveSite(SiteDraft draft, {int? id}) => _save('sites', draft.toJson(), id);

  @override
  Future<void> saveSpecialty(SpecialtyDraft draft, {int? id}) =>
      _save('specialties', draft.toJson(), id);

  @override
  Future<void> setSiteActive(int id, {required bool isActive}) =>
      _save('sites', {'is_active': isActive}, id);

  @override
  Future<void> setSpecialtyActive(int id, {required bool isActive}) =>
      _save('specialties', {'is_active': isActive}, id);

  Future<void> _save(String table, Map<String, dynamic> values, int? id) =>
      SupabaseErrorMapper.guard(() async {
        if (id == null) {
          await _client.from(table).insert(values);
          return;
        }
        // .select() devuelve las filas tocadas: si la RLS bloquea, viene vacío.
        final updated = await _client.from(table).update(values).eq('id', id).select('id');
        if (updated.isEmpty) {
          throw const AppException('No tienes permiso para realizar esta acción.');
        }
      }, messagesByCode: _duplicateName);
}
