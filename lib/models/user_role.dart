/// Roles del sistema. El valor `name` coincide con la columna `role` en Supabase.
enum UserRole {
  patient('Paciente'),
  doctor('Médico'),
  receptionist('Recepción'),
  admin('Administrador');

  const UserRole(this.label);
  final String label;

  bool get isStaff => this != UserRole.patient;

  static UserRole fromString(String value) => UserRole.values.firstWhere(
        (role) => role.name == value,
        orElse: () => throw ArgumentError('Rol desconocido: $value'),
      );
}
