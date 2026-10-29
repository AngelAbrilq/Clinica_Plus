/// Bloque de atención semanal de un médico (tabla `doctor_schedules`).
class DoctorSchedule {
  const DoctorSchedule({
    required this.id,
    required this.doctorId,
    required this.siteId,
    required this.siteName,
    required this.weekday,
    required this.startTime,
    required this.endTime,
  });

  final int id;
  final int doctorId;
  final int siteId;
  final String siteName;

  /// ISO 8601: 1 = lunes … 7 = domingo.
  final int weekday;

  /// Formato 'HH:mm'.
  final String startTime;
  final String endTime;

  factory DoctorSchedule.fromJson(Map<String, dynamic> json) {
    final site = json['sites'] as Map<String, dynamic>?;
    return DoctorSchedule(
      id: (json['id'] as num).toInt(),
      doctorId: (json['doctor_id'] as num).toInt(),
      siteId: (json['site_id'] as num).toInt(),
      siteName: (site?['name'] as String?) ?? '',
      weekday: (json['weekday'] as num).toInt(),
      startTime: _toHourMinute(json['start_time'] as String),
      endTime: _toHourMinute(json['end_time'] as String),
    );
  }

  /// Postgres devuelve 'HH:mm:ss'; la app trabaja con 'HH:mm'.
  static String _toHourMinute(String value) =>
      value.length >= 5 ? value.substring(0, 5) : value;
}

/// Datos para crear un horario nuevo.
class NewDoctorSchedule {
  const NewDoctorSchedule({
    required this.doctorId,
    required this.siteId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
  });

  final int doctorId;
  final int siteId;
  final int weekday;
  final String startTime;
  final String endTime;

  Map<String, dynamic> toJson() => {
        'doctor_id': doctorId,
        'site_id': siteId,
        'weekday': weekday,
        'start_time': startTime,
        'end_time': endTime,
      };
}
