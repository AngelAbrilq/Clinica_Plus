import 'user_role.dart';

/// Tipos de evento auditados (columna `audit_logs.action`).
enum AuditAction {
  readHistory('READ_HISTORY', 'Consultó la historia de'),
  insert('INSERT', 'Registró una consulta de'),
  update('UPDATE', 'Modificó la historia de'),
  delete('DELETE', 'Eliminó un registro de'),
  unknown('', 'Acción sobre');

  const AuditAction(this.dbValue, this.sentence);
  final String dbValue;

  /// Frase para "Dr. Ruiz [consultó la historia de] Ana Gómez".
  final String sentence;

  static AuditAction fromDb(String value) => AuditAction.values.firstWhere(
    (action) => action.dbValue == value,
    orElse: () => AuditAction.unknown,
  );
}

/// Un evento de la bitácora (resultado de `admin_get_audit_logs`).
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.createdAt,
    required this.action,
    required this.actorName,
    this.actorRole,
    this.patientName,
  });

  final int id;
  final DateTime createdAt;
  final AuditAction action;
  final String actorName;
  final UserRole? actorRole;
  final String? patientName;

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    final role = json['actor_role'] as String?;
    return AuditEntry(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      action: AuditAction.fromDb(json['action'] as String),
      actorName: json['actor_name'] as String,
      actorRole: role == null ? null : UserRole.fromString(role),
      patientName: json['patient_name'] as String?,
    );
  }
}
