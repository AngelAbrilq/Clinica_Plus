/// Paciente con relación de atención con el médico autenticado
/// (resultado de `get_my_patients`).
class DoctorPatient {
  const DoctorPatient({
    required this.id,
    required this.name,
    required this.completedVisits,
    this.document,
    this.age,
    this.lastVisitAt,
    this.nextVisitAt,
  });

  final String id;
  final String name;
  final String? document;
  final int? age;
  final int completedVisits;
  final DateTime? lastVisitAt;
  final DateTime? nextVisitAt;

  String get initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  factory DoctorPatient.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String key) {
      final value = json[key] as String?;
      return value == null ? null : DateTime.parse(value).toLocal();
    }

    return DoctorPatient(
      id: json['patient_id'] as String,
      name: json['patient_name'] as String,
      document: json['patient_document'] as String?,
      age: (json['patient_age'] as num?)?.toInt(),
      completedVisits: (json['completed_visits'] as num).toInt(),
      lastVisitAt: parseDate('last_visit_at'),
      nextVisitAt: parseDate('next_visit_at'),
    );
  }
}
