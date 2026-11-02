/// Indicadores de la clínica para un rango (resultado de `admin_get_metrics`).
class ClinicMetrics {
  const ClinicMetrics({
    required this.total,
    required this.completed,
    required this.cancelled,
    required this.noShow,
    required this.pending,
    required this.capacityMinutes,
    required this.bookedMinutes,
    required this.bySpecialty,
    required this.byDay,
  });

  final int total;
  final int completed;
  final int cancelled;
  final int noShow;
  final int pending;
  final int capacityMinutes;
  final int bookedMinutes;
  final List<SpecialtyMetric> bySpecialty;
  final List<DailyCount> byDay;

  /// Minutos agendados sobre minutos de agenda publicada (0..1).
  double get occupancyRate => capacityMinutes == 0 ? 0 : bookedMinutes / capacityMinutes;

  /// Sobre las citas que ya debían ocurrir (atendidas + inasistencias).
  double get noShowRate {
    final due = completed + noShow;
    return due == 0 ? 0 : noShow / due;
  }

  double get cancellationRate => total == 0 ? 0 : cancelled / total;

  int get busiestDayTotal =>
      byDay.fold<int>(0, (max, day) => day.total > max ? day.total : max);

  factory ClinicMetrics.fromJson(Map<String, dynamic> json) {
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;
    return ClinicMetrics(
      total: read('total'),
      completed: read('completed'),
      cancelled: read('cancelled'),
      noShow: read('no_show'),
      pending: read('pending'),
      capacityMinutes: read('capacity_minutes'),
      bookedMinutes: read('booked_minutes'),
      bySpecialty: [
        for (final raw in (json['by_specialty'] as List<dynamic>? ?? const []))
          SpecialtyMetric.fromJson(raw as Map<String, dynamic>),
      ],
      byDay: [
        for (final raw in (json['by_day'] as List<dynamic>? ?? const []))
          DailyCount.fromJson(raw as Map<String, dynamic>),
      ],
    );
  }
}

class SpecialtyMetric {
  const SpecialtyMetric({
    required this.name,
    required this.total,
    required this.completed,
    required this.noShow,
    required this.cancelled,
  });

  final String name;
  final int total;
  final int completed;
  final int noShow;
  final int cancelled;

  factory SpecialtyMetric.fromJson(Map<String, dynamic> json) => SpecialtyMetric(
    name: json['name'] as String,
    total: (json['total'] as num).toInt(),
    completed: (json['completed'] as num).toInt(),
    noShow: (json['no_show'] as num).toInt(),
    cancelled: (json['cancelled'] as num).toInt(),
  );
}

class DailyCount {
  const DailyCount({required this.date, required this.total});

  final DateTime date;
  final int total;

  /// La fecha llega como 'yyyy-MM-dd' (día de Bogotá, sin hora).
  factory DailyCount.fromJson(Map<String, dynamic> json) => DailyCount(
    date: DateTime.parse(json['date'] as String),
    total: (json['total'] as num).toInt(),
  );
}
