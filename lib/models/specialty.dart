/// Especialidad médica (tabla `specialties`).
class Specialty {
  const Specialty({
    required this.id,
    required this.name,
    required this.slotMinutes,
    this.description,
    this.isActive = true,
  });

  /// Límites del CHECK `slot_minutes between 10 and 120` en la base de datos.
  static const int minSlotMinutes = 10;
  static const int maxSlotMinutes = 120;

  final int id;
  final String name;
  final int slotMinutes;
  final String? description;
  final bool isActive;

  factory Specialty.fromJson(Map<String, dynamic> json) => Specialty(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    slotMinutes: (json['slot_minutes'] as num?)?.toInt() ?? 20,
    description: json['description'] as String?,
    isActive: (json['is_active'] as bool?) ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slot_minutes': slotMinutes,
    'description': description,
    'is_active': isActive,
  };
}

/// Datos para crear o editar una especialidad.
class SpecialtyDraft {
  const SpecialtyDraft({
    required this.name,
    required this.slotMinutes,
    this.description,
  });

  final String name;
  final int slotMinutes;
  final String? description;

  Map<String, dynamic> toJson() {
    final trimmed = description?.trim();
    return {
      'name': name.trim(),
      'slot_minutes': slotMinutes,
      'description': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    };
  }
}
