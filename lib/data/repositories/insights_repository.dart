import '../../models/audit_entry.dart';
import '../../models/clinic_metrics.dart';
import '../../models/site.dart';

/// Indicadores y auditoría (solo administración).
abstract interface class InsightsRepository {
  /// Sedes activas (para filtrar indicadores).
  Future<List<Site>> fetchSites();

  /// [siteId] null = todas las sedes. Fechas inclusive.
  Future<ClinicMetrics> fetchMetrics({
    required DateTime from,
    required DateTime to,
    int? siteId,
  });

  /// Página de la bitácora, del más reciente al más antiguo.
  /// [beforeId]: cursor (id del último elemento de la página anterior).
  Future<List<AuditEntry>> fetchAuditLog({
    int limit = 30,
    int? beforeId,
    AuditAction? action,
  });
}
