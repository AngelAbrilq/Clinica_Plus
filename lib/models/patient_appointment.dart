import 'appointment_status.dart';

/// Cita vista por el paciente (resultado de `get_my_appointments`).
class PatientAppointment {
  const PatientAppointment({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.confirmationToken,
    required this.specialtyName,
    required this.siteName,
    required this.siteAddress,
    required this.doctorName,
    this.symptoms,
    this.cancelReason,
  });

  /// Igual a la regla de `cancel_appointment` en la base de datos.
  static const Duration freeCancellationWindow = Duration(hours: 2);

  static const Set<AppointmentStatus> _cancellableStatuses = {
    AppointmentStatus.requested,
    AppointmentStatus.assigned,
    AppointmentStatus.confirmed,
  };

  final int id;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final AppointmentStatus status;
  final String confirmationToken;
  final String specialtyName;
  final String siteName;
  final String siteAddress;
  final String doctorName;
  final String? symptoms;
  final String? cancelReason;

  /// Contenido del QR que escanea recepción.
  String get checkInCode => 'clinicaplus:checkin:$confirmationToken';

  bool isUpcoming(DateTime now) =>
      status.isActive && startsAt != null && (endsAt ?? startsAt!).isAfter(now);

  bool canCancel(DateTime now) =>
      _cancellableStatuses.contains(status) &&
      startsAt != null &&
      startsAt!.difference(now) >= freeCancellationWindow;

  factory PatientAppointment.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String key) {
      final value = json[key] as String?;
      return value == null ? null : DateTime.parse(value).toLocal();
    }

    return PatientAppointment(
      id: (json['id'] as num).toInt(),
      startsAt: parseDate('starts_at'),
      endsAt: parseDate('ends_at'),
      status: AppointmentStatus.fromDb(json['status'] as String),
      confirmationToken: json['confirmation_token'] as String,
      specialtyName: json['specialty_name'] as String,
      siteName: json['site_name'] as String,
      siteAddress: (json['site_address'] as String?) ?? '',
      doctorName: (json['doctor_name'] as String?) ?? 'Médico asignado',
      symptoms: json['symptoms'] as String?,
      cancelReason: json['cancel_reason'] as String?,
    );
  }
}
