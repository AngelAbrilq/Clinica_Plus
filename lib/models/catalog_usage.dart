/// Uso de una sede o especialidad (resultado de `admin_catalog_overview`).
class CatalogUsage {
  const CatalogUsage({required this.doctors, required this.upcomingAppointments});

  static const CatalogUsage empty = CatalogUsage(doctors: 0, upcomingAppointments: 0);

  /// Sede: médicos con horario ahí. Especialidad: médicos activos.
  final int doctors;
  final int upcomingAppointments;

  bool get isInUse => doctors > 0 || upcomingAppointments > 0;
}

class CatalogOverview {
  const CatalogOverview({required this.sites, required this.specialties});

  static const CatalogOverview empty = CatalogOverview(sites: {}, specialties: {});

  final Map<int, CatalogUsage> sites;
  final Map<int, CatalogUsage> specialties;

  CatalogUsage siteUsage(int id) => sites[id] ?? CatalogUsage.empty;
  CatalogUsage specialtyUsage(int id) => specialties[id] ?? CatalogUsage.empty;

  factory CatalogOverview.fromJson(Map<String, dynamic> json) {
    Map<int, CatalogUsage> parse(String key, String doctorsKey) => {
      for (final raw in (json[key] as List<dynamic>? ?? const []))
        ((raw as Map<String, dynamic>)['id'] as num).toInt(): CatalogUsage(
          doctors: (raw[doctorsKey] as num).toInt(),
          upcomingAppointments: (raw['upcoming_appointments'] as num).toInt(),
        ),
    };
    return CatalogOverview(
      sites: parse('sites', 'scheduled_doctors'),
      specialties: parse('specialties', 'active_doctors'),
    );
  }
}
