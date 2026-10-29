import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/site.dart';
import '../../models/specialty.dart';
import 'supabase_error_mapper.dart';

/// Consultas de catálogos (sedes y especialidades) compartidas por varios
/// repositorios, para no duplicar código (DRY).
abstract final class CatalogQueries {
  static Future<List<Site>> fetchSites(SupabaseClient client) =>
      SupabaseErrorMapper.guard(() async {
        final rows = await client
            .from('sites')
            .select()
            .eq('is_active', true)
            .order('name');
        return rows.map(Site.fromJson).toList();
      });

  static Future<List<Specialty>> fetchSpecialties(SupabaseClient client) =>
      SupabaseErrorMapper.guard(() async {
        final rows = await client
            .from('specialties')
            .select()
            .eq('is_active', true)
            .order('name');
        return rows.map(Specialty.fromJson).toList();
      });
}
