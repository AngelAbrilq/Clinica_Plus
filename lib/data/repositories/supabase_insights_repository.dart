import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/audit_entry.dart';
import '../../models/clinic_metrics.dart';
import '../../models/site.dart';
import '../services/catalog_queries.dart';
import '../services/supabase_error_mapper.dart';
import 'insights_repository.dart';

class SupabaseInsightsRepository implements InsightsRepository {
  SupabaseInsightsRepository(this._client);

  final SupabaseClient _client;
  static final DateFormat _sqlDate = DateFormat('yyyy-MM-dd');

  @override
  Future<List<Site>> fetchSites() => CatalogQueries.fetchSites(_client);

  @override
  Future<ClinicMetrics> fetchMetrics({
    required DateTime from,
    required DateTime to,
    int? siteId,
  }) => SupabaseErrorMapper.guard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'admin_get_metrics',
      params: {
        'p_from': _sqlDate.format(from),
        'p_to': _sqlDate.format(to),
        'p_site_id': siteId,
      },
    );
    return ClinicMetrics.fromJson(json);
  });

  @override
  Future<List<AuditEntry>> fetchAuditLog({
    int limit = 30,
    int? beforeId,
    AuditAction? action,
  }) => SupabaseErrorMapper.guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'admin_get_audit_logs',
      params: {
        'p_limit': limit,
        'p_before_id': beforeId,
        'p_action': (action == null || action == AuditAction.unknown) ? null : action.dbValue,
      },
    );
    return rows.cast<Map<String, dynamic>>().map(AuditEntry.fromJson).toList();
  });
}
