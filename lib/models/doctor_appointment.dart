import 'appointment_status.dart';

/// Grupos de la agenda del médico, en orden de prioridad.
enum DoctorAgendaGroup {
  inProgress('En consulta'),
  waiting('En sala'),
  upcoming('Por llegar'),
  done('Finalizadas');

  const DoctorAgendaGroup(this.label);
  final String label;
}

/// Cita en la agenda del médico (resultado de `get_doctor_agenda`).
class DoctorAppointment {
  const DoctorAppointment({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.patientName,
    required this.siteName,
    required this.specialtyName,
    required this.hasRecord,
    this.checkedInAt,
    this.patientAge,
    this.symptoms,
  });

  final int id;
  final DateTime startsAt;
  final DateTime endsAt;
  final AppointmentStatus status;
  final DateTime? checkedInAt;
  final String patientName;
  final int? patientAge;
  final String siteName;
  final String specialtyName;
  final String? symptoms;
  final bool hasRecord;

  DoctorAgendaGroup get group => switch (status) {
    AppointmentStatus.inProgress => DoctorAgendaGroup.inProgress,
    AppointmentStatus.checkedIn => DoctorAgendaGroup.waiting,
    AppointmentStatus.requested ||
    AppointmentStatus.assigned ||
    AppointmentStatus.confirmed => DoctorAgendaGroup.upcoming,
    AppointmentStatus.completed ||
    AppointmentStatus.cancelled ||
    AppointmentStatus.noShow => DoctorAgendaGroup.done,
  };

  /// Minutos que lleva el paciente en sala (null si no ha llegado).
  int? minutesWaiting(DateTime now) =>
      status == AppointmentStatus.checkedIn && checkedInAt != null
      ? now.difference(checkedInAt!).inMinutes
      : null;

  factory DoctorAppointment.fromJson(Map<String, dynamic> json) {
    final checkedIn = json['checked_in_at'] as String?;
    return DoctorAppointment(
      id: (json['id'] as num).toInt(),
      startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
      status: AppointmentStatus.fromDb(json['status'] as String),
      checkedInAt: checkedIn == null
          ? null
          : DateTime.parse(checkedIn).toLocal(),
      patientName: json['patient_name'] as String,
      patientAge: (json['patient_age'] as num?)?.toInt(),
      siteName: json['site_name'] as String,
      specialtyName: json['specialty_name'] as String,
      symptoms: json['symptoms'] as String?,
      hasRecord: (json['has_record'] as bool?) ?? false,
    );
  }
}

/// Detalle de una consulta (resultado de `get_consultation`).
class ConsultationDetail {
  const ConsultationDetail({
    required this.id,
    required this.startsAt,
    required this.status,
    required this.patientName,
    required this.specialtyName,
    required this.siteName,
    this.checkedInAt,
    this.patientDocument,
    this.patientAge,
    this.symptoms,
    this.recordId,
    this.reason,
    this.clinicalNotes,
    this.diagnosisCode,
    this.diagnosisDescription,
  });

  final int id;
  final DateTime startsAt;
  final AppointmentStatus status;
  final DateTime? checkedInAt;
  final String patientName;
  final String? patientDocument;
  final int? patientAge;
  final String specialtyName;
  final String siteName;
  final String? symptoms;
  final int? recordId;
  final String? reason;
  final String? clinicalNotes;
  final String? diagnosisCode;
  final String? diagnosisDescription;

  bool get canStart => status == AppointmentStatus.checkedIn;
  bool get isInProgress => status == AppointmentStatus.inProgress;
  bool get isCompleted => status == AppointmentStatus.completed;

  factory ConsultationDetail.fromJson(Map<String, dynamic> json) {
    String? text(String key) => json[key] as String?;
    final checkedIn = text('checked_in_at');
    return ConsultationDetail(
      id: (json['id'] as num).toInt(),
      startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
      status: AppointmentStatus.fromDb(json['status'] as String),
      checkedInAt: checkedIn == null
          ? null
          : DateTime.parse(checkedIn).toLocal(),
      patientName: json['patient_name'] as String,
      patientDocument: text('patient_document'),
      patientAge: (json['patient_age'] as num?)?.toInt(),
      specialtyName: json['specialty_name'] as String,
      siteName: json['site_name'] as String,
      symptoms: text('symptoms'),
      recordId: (json['record_id'] as num?)?.toInt(),
      reason: text('reason'),
      clinicalNotes: text('clinical_notes'),
      diagnosisCode: text('diagnosis_code'),
      diagnosisDescription: text('diagnosis_description'),
    );
  }
}

/// Datos que el médico registra al finalizar la consulta.
class ConsultationNote {
  const ConsultationNote({
    required this.reason,
    required this.diagnosisCode,
    required this.diagnosisDescription,
    this.clinicalNotes,
  });

  final String reason;
  final String? clinicalNotes;
  final String diagnosisCode;
  final String diagnosisDescription;
}
