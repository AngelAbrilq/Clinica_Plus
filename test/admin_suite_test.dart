import 'package:clinica_plus/data/repositories/catalog_admin_repository.dart';
import 'package:clinica_plus/data/repositories/insights_repository.dart';
import 'package:clinica_plus/models/audit_entry.dart';
import 'package:clinica_plus/models/catalog_usage.dart';
import 'package:clinica_plus/models/clinic_metrics.dart';
import 'package:clinica_plus/models/site.dart';
import 'package:clinica_plus/models/specialty.dart';
import 'package:clinica_plus/models/user_role.dart';
import 'package:clinica_plus/providers/audit_provider.dart';
import 'package:clinica_plus/providers/catalog_admin_provider.dart';
import 'package:clinica_plus/providers/metrics_provider.dart';
import 'package:clinica_plus/utils/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------- fakes

class FakeCatalogRepository implements CatalogAdminRepository {
  List<Site> sites = [
    const Site(id: 1, name: 'Sede Principal', address: 'Calle 1'),
    const Site(id: 2, name: 'Sede Antigua', address: 'Calle 9', isActive: false),
  ];
  List<Specialty> specialties = [
    const Specialty(id: 1, name: 'Pediatría', slotMinutes: 30),
  ];
  AppException? nextError;
  final List<String> calls = [];

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
  }

  @override
  Future<List<Site>> fetchAllSites() async => sites;

  @override
  Future<List<Specialty>> fetchAllSpecialties() async => specialties;

  @override
  Future<CatalogOverview> fetchOverview() async => const CatalogOverview(
    sites: {1: CatalogUsage(doctors: 2, upcomingAppointments: 5)},
    specialties: {},
  );

  @override
  Future<void> saveSite(SiteDraft draft, {int? id}) async {
    _throwIfNeeded();
    calls.add('saveSite:${id ?? 'new'}:${draft.toJson()['name']}');
  }

  @override
  Future<void> saveSpecialty(SpecialtyDraft draft, {int? id}) async {
    _throwIfNeeded();
    calls.add('saveSpecialty:${id ?? 'new'}:${draft.slotMinutes}');
  }

  @override
  Future<void> setSiteActive(int id, {required bool isActive}) async {
    calls.add('setSiteActive:$id:$isActive');
  }

  @override
  Future<void> setSpecialtyActive(int id, {required bool isActive}) async {
    calls.add('setSpecialtyActive:$id:$isActive');
  }
}

class FakeInsightsRepository implements InsightsRepository {
  final List<AuditEntry> log = [
    for (var id = 75; id >= 1; id--)
      AuditEntry(
        id: id,
        createdAt: DateTime(2026, 11, 2, 9).subtract(Duration(minutes: 75 - id)),
        action: id.isEven ? AuditAction.readHistory : AuditAction.insert,
        actorName: 'Dr. Ruiz',
        actorRole: UserRole.doctor,
        patientName: 'Ana Gómez',
      ),
  ];
  DateTime? lastFrom;
  DateTime? lastTo;
  int? lastSiteId;

  @override
  Future<List<Site>> fetchSites() async =>
      const [Site(id: 1, name: 'Sede Principal', address: '')];

  @override
  Future<ClinicMetrics> fetchMetrics({
    required DateTime from,
    required DateTime to,
    int? siteId,
  }) async {
    lastFrom = from;
    lastTo = to;
    lastSiteId = siteId;
    return ClinicMetrics.fromJson(_metricsJson);
  }

  @override
  Future<List<AuditEntry>> fetchAuditLog({
    int limit = 30,
    int? beforeId,
    AuditAction? action,
  }) async => log
      .where((entry) => beforeId == null || entry.id < beforeId)
      .where((entry) => action == null || entry.action == action)
      .take(limit)
      .toList();
}

const Map<String, dynamic> _metricsJson = {
  'total': 20,
  'completed': 12,
  'cancelled': 2,
  'no_show': 3,
  'pending': 3,
  'capacity_minutes': 1200,
  'booked_minutes': 540,
  'by_specialty': [
    {'name': 'Pediatría', 'total': 12, 'completed': 8, 'no_show': 2, 'cancelled': 1},
    {'name': 'Medicina General', 'total': 8, 'completed': 4, 'no_show': 1, 'cancelled': 1},
  ],
  'by_day': [
    {'date': '2026-11-01', 'total': 0},
    {'date': '2026-11-02', 'total': 7},
  ],
};

// ---------------------------------------------------------------- tests

void main() {
  group('Modelos', () {
    test('ClinicMetrics calcula tasas correctamente', () {
      final metrics = ClinicMetrics.fromJson(_metricsJson);
      expect(metrics.occupancyRate, closeTo(0.45, 0.001));
      // 3 inasistencias de 15 citas que debían ocurrir (12 + 3)
      expect(metrics.noShowRate, closeTo(0.2, 0.001));
      expect(metrics.cancellationRate, closeTo(0.1, 0.001));
      expect(metrics.busiestDayTotal, 7);
      expect(metrics.byDay.first.date, DateTime(2026, 11, 1));
    });

    test('sin datos las tasas son 0 (sin dividir por cero)', () {
      final empty = ClinicMetrics.fromJson(const {});
      expect(empty.occupancyRate, 0);
      expect(empty.noShowRate, 0);
      expect(empty.cancellationRate, 0);
    });

    test('CatalogOverview lee sedes y especialidades', () {
      final overview = CatalogOverview.fromJson(const {
        'sites': [
          {'id': 1, 'scheduled_doctors': 2, 'upcoming_appointments': 4},
        ],
        'specialties': [
          {'id': 3, 'active_doctors': 0, 'upcoming_appointments': 0},
        ],
      });
      expect(overview.siteUsage(1).isInUse, isTrue);
      expect(overview.specialtyUsage(3).isInUse, isFalse);
      expect(overview.siteUsage(99).doctors, 0); // desconocido = vacío
    });

    test('SiteDraft y SpecialtyDraft limpian textos opcionales vacíos', () {
      expect(const SiteDraft(name: ' Norte ', address: 'Calle 2', phone: '  ').toJson(), {
        'name': 'Norte',
        'address': 'Calle 2',
        'phone': null,
      });
      expect(
        const SpecialtyDraft(name: 'Dermatología', slotMinutes: 20, description: '').toJson()['description'],
        isNull,
      );
    });

    test('AuditAction desconocida no rompe la lectura', () {
      expect(AuditAction.fromDb('LOGIN'), AuditAction.unknown);
    });
  });

  group('CatalogAdminProvider', () {
    late FakeCatalogRepository repository;
    late CatalogAdminProvider provider;

    setUp(() async {
      repository = FakeCatalogRepository();
      provider = CatalogAdminProvider(repository);
      await provider.load();
    });

    test('ordena activas primero', () {
      expect(provider.sortedSites.map((site) => site.isActive), [true, false]);
      expect(provider.overview.siteUsage(1).upcomingAppointments, 5);
    });

    test('crear y editar envían id correcto', () async {
      await provider.saveSite(const SiteDraft(name: 'Sede Sur', address: 'Cra 5'));
      await provider.saveSpecialty(
        const SpecialtyDraft(name: 'Pediatría', slotMinutes: 25),
        id: 1,
      );
      expect(repository.calls, ['saveSite:new:Sede Sur', 'saveSpecialty:1:25']);
    });

    test('nombre duplicado: devuelve false y muestra el error', () async {
      repository.nextError = const AppException('Ya existe un registro con ese nombre.');
      final saved = await provider.saveSite(const SiteDraft(name: 'Sede Principal', address: 'x'));
      expect(saved, isFalse);
      expect(provider.errorMessage, 'Ya existe un registro con ese nombre.');
      expect(provider.isSaving, isFalse);
    });

    test('activar/desactivar', () async {
      await provider.setSiteActive(provider.sites.last, isActive: true);
      expect(repository.calls.single, 'setSiteActive:2:true');
    });
  });

  group('MetricsProvider', () {
    test('el periodo termina hoy e incluye N días', () async {
      final repository = FakeInsightsRepository();
      final provider = MetricsProvider(repository, clock: () => DateTime(2026, 11, 2, 15));
      await provider.initialize();
      expect(repository.lastTo, DateTime(2026, 11, 2));
      expect(repository.lastFrom, DateTime(2026, 10, 4)); // 30 días contando hoy

      await provider.selectPeriod(MetricsPeriod.week);
      expect(repository.lastFrom, DateTime(2026, 10, 27));

      await provider.selectSite(1);
      expect(repository.lastSiteId, 1);
      expect(provider.sites, hasLength(1));
      expect(provider.metrics?.total, 20);
    });
  });

  group('AuditProvider', () {
    test('pagina por cursor sin repetir ni saltar eventos', () async {
      final provider = AuditProvider(FakeInsightsRepository());
      await provider.refresh();
      await provider.loadMore();
      await provider.loadMore();
      final ids = provider.entries.map((entry) => entry.id).toList();
      expect(ids, hasLength(75));
      expect(ids.toSet(), hasLength(75));
      expect(ids.first, 75);
      expect(ids.last, 1);
      expect(provider.hasMore, isFalse);
    });

    test('el filtro reinicia la lista', () async {
      final provider = AuditProvider(FakeInsightsRepository());
      await provider.refresh();
      await provider.selectFilter(AuditAction.readHistory);
      expect(
        provider.entries.every((entry) => entry.action == AuditAction.readHistory),
        isTrue,
      );
    });
  });
}
