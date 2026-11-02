/// Especialidad médica (tabla `specialties`).
class Specialty {
  const Specialty({
    required this.id,
    required this.name,
    required this.slotMinutes,
    this.description,
  });

  final int id;
  final String name;
  final int slotMinutes;
  final String? description;

  factory Specialty.fromJson(Map<String, dynamic> json) => Specialty(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    slotMinutes: (json['slot_minutes'] as num?)?.toInt() ?? 20,
    description: json['description'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slot_minutes': slotMinutes,
    'description': description,
  };
}
