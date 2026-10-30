/// Registro de una consulta en la historia clínica.
class MedicalRecord {
  const MedicalRecord({
    required this.id,
    required this.consultedAt,
    required this.specialtyName,
    required this.doctorName,
    required this.reason,
    this.clinicalNotes,
    this.diagnosisCode,
    this.diagnosisDescription,
  });

  final int id;
  final DateTime consultedAt;
  final String specialtyName;
  final String doctorName;
  final String reason;
  final String? clinicalNotes;
  final String? diagnosisCode;
  final String? diagnosisDescription;

  /// "J06.9 Infección aguda de las vías respiratorias…"
  String get diagnosisLabel => [
    if (diagnosisCode != null) diagnosisCode!,
    if (diagnosisDescription != null) diagnosisDescription!,
  ].join(' ');

  factory MedicalRecord.fromJson(Map<String, dynamic> json) => MedicalRecord(
    id: (json['record_id'] as num).toInt(),
    consultedAt: DateTime.parse(json['consulted_at'] as String).toLocal(),
    specialtyName: json['specialty_name'] as String,
    doctorName: json['doctor_name'] as String,
    reason: json['reason'] as String,
    clinicalNotes: json['clinical_notes'] as String?,
    diagnosisCode: json['diagnosis_code'] as String?,
    diagnosisDescription: json['diagnosis_description'] as String?,
  );
}
