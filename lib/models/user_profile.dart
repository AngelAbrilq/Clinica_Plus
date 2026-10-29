import 'document_type.dart';
import 'user_role.dart';

/// Perfil de usuario (tabla `profiles` en Supabase).
/// [role] es `null` cuando es personal pendiente de aprobación.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.role,
    this.documentType,
    this.documentNumber,
    this.phone,
    this.birthDate,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole? role;
  final DocumentType? documentType;
  final String? documentNumber;
  final String? phone;
  final DateTime? birthDate;

  bool get isPendingApproval => role == null;

  String get firstName =>
      fullName.trim().isEmpty ? email.split('@').first : fullName.trim().split(' ').first;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final roleValue = json['role'] as String?;
    final birthValue = json['birth_date'] as String?;
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: (json['full_name'] as String?) ?? '',
      role: roleValue == null ? null : UserRole.fromString(roleValue),
      documentType: DocumentType.tryParse(json['document_type'] as String?),
      documentNumber: json['document_number'] as String?,
      phone: json['phone'] as String?,
      birthDate: birthValue == null ? null : DateTime.parse(birthValue),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role?.name,
        'document_type': documentType?.dbValue,
        'document_number': documentNumber,
        'phone': phone,
        'birth_date': birthDate?.toIso8601String().split('T').first,
      };
}
