import '../config/constants/app_constants.dart';
import 'appointment_status.dart';

/// Grupos de la agenda de recepción.
enum ReceptionGroup {
  pending('Por llegar'),
  inClinic('En sala'),
  closed('Cerradas');

  const ReceptionGroup(this.label);
  final String label;
}

/// Cita vista por recepción (resultado de `get_reception_agenda`).
class ReceptionAppointment {
  const ReceptionAppointment({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.patientName,
    required this.specialtyName,
    required this.doctorName,
    this.checkedInAt,
    this.patientDocument,
    this.patientPhone,
  });

  final int id;
  final DateTime startsAt;
  final DateTime endsAt;
  final AppointmentStatus status;
  final DateTime? checkedInAt;
  final String patientName;
  final String? patientDocument;
  final String? patientPhone;
  final String specialtyName;
  final String doctorName;

  bool get isPending =>
      status == AppointmentStatus.assigned ||
      status == AppointmentStatus.confirmed;

  ReceptionGroup get group => switch (status) {
    AppointmentStatus.requested ||
    AppointmentStatus.assigned ||
    AppointmentStatus.confirmed => ReceptionGroup.pending,
    AppointmentStatus.checkedIn ||
    AppointmentStatus.inProgress => ReceptionGroup.inClinic,
    AppointmentStatus.completed ||
    AppointmentStatus.cancelled ||
    AppointmentStatus.noShow => ReceptionGroup.closed,
  };

  DateTime get _toleranceLimit => startsAt.add(AppConstants.lateTolerance);

  /// Mismas reglas que `private.check_in` en la base de datos.
  bool canCheckIn(DateTime now) =>
      isPending &&
      DateTime(now.year, now.month, now.day) ==
          DateTime(startsAt.year, startsAt.month, startsAt.day) &&
      !now.isAfter(_toleranceLimit);

  /// Igual que `mark_no_show`: solo después de la tolerancia.
  bool canMarkNoShow(DateTime now) =>
      isPending && !now.isBefore(_toleranceLimit);

  /// Pendiente y ya pasó su hora (pero aún dentro de la tolerancia).
  bool isRunningLate(DateTime now) => isPending && now.isAfter(startsAt);

  factory ReceptionAppointment.fromJson(Map<String, dynamic> json) {
    final checkedIn = json['checked_in_at'] as String?;
    return ReceptionAppointment(
      id: (json['id'] as num).toInt(),
      startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
      status: AppointmentStatus.fromDb(json['status'] as String),
      checkedInAt: checkedIn == null
          ? null
          : DateTime.parse(checkedIn).toLocal(),
      patientName: json['patient_name'] as String,
      patientDocument: json['patient_document'] as String?,
      patientPhone: json['patient_phone'] as String?,
      specialtyName: json['specialty_name'] as String,
      doctorName: json['doctor_name'] as String,
    );
  }
}

/// Respuesta de un check-in exitoso.
class CheckInResult {
  const CheckInResult({
    required this.appointmentId,
    required this.patientName,
    required this.specialtyName,
    required this.doctorName,
    required this.startsAt,
    required this.minutesUntilStart,
  });

  final int appointmentId;
  final String patientName;
  final String specialtyName;
  final String doctorName;
  final DateTime startsAt;

  /// Negativo si llegó después de la hora (dentro de la tolerancia).
  final int minutesUntilStart;

  factory CheckInResult.fromJson(Map<String, dynamic> json) => CheckInResult(
    appointmentId: (json['appointment_id'] as num).toInt(),
    patientName: json['patient_name'] as String,
    specialtyName: json['specialty_name'] as String,
    doctorName: json['doctor_name'] as String,
    startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
    minutesUntilStart: (json['minutes_until_start'] as num).toInt(),
  );
}
