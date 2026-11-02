import 'appointment_status.dart';

/// Posición del paciente en la sala de espera (`get_my_queue_status`).
class QueueStatus {
  const QueueStatus({
    required this.status,
    required this.startsAt,
    required this.peopleAhead,
    required this.specialtyName,
    required this.doctorName,
    required this.siteName,
    this.estimatedStart,
  });

  final AppointmentStatus status;
  final DateTime startsAt;
  final int peopleAhead;

  /// Hora estimada de atención (null si ya está en consulta o terminó).
  final DateTime? estimatedStart;
  final String specialtyName;
  final String doctorName;
  final String siteName;

  bool get isYourTurn => status == AppointmentStatus.inProgress;
  bool get isWaitingInRoom => status == AppointmentStatus.checkedIn;
  bool get hasNotArrived =>
      status == AppointmentStatus.assigned || status == AppointmentStatus.confirmed;
  bool get isOver => status.isFinal;

  /// Minutos estimados de espera desde [now] (nunca negativo).
  int? minutesUntilEstimated(DateTime now) {
    final estimated = estimatedStart;
    if (estimated == null) return null;
    final minutes = estimated.difference(now).inMinutes;
    return minutes < 0 ? 0 : minutes;
  }

  factory QueueStatus.fromJson(Map<String, dynamic> json) {
    final estimated = json['estimated_start'] as String?;
    return QueueStatus(
      status: AppointmentStatus.fromDb(json['status'] as String),
      startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
      peopleAhead: (json['people_ahead'] as num).toInt(),
      estimatedStart: estimated == null ? null : DateTime.parse(estimated).toLocal(),
      specialtyName: json['specialty_name'] as String,
      doctorName: json['doctor_name'] as String,
      siteName: json['site_name'] as String,
    );
  }
}
