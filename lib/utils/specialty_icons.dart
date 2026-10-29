import 'package:material_ui/material_ui.dart';

/// Ícono representativo por especialidad (por palabra clave del nombre).
abstract final class SpecialtyIcons {
  static const Map<String, IconData> _byKeyword = {
    'pediatr': Icons.child_care_rounded,
    'ginecolog': Icons.pregnant_woman_rounded,
    'odontolog': Icons.mood_rounded,
    'psicolog': Icons.psychology_rounded,
    'interna': Icons.monitor_heart_rounded,
    'general': Icons.medical_services_rounded,
  };

  static IconData forName(String name) {
    final normalized = name.toLowerCase();
    for (final entry in _byKeyword.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }
    return Icons.local_hospital_rounded;
  }
}
