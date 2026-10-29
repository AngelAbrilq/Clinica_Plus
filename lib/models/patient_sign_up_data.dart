import 'document_type.dart';

/// Datos del formulario de registro de paciente.
class PatientSignUpData {
  const PatientSignUpData({
    required this.fullName,
    required this.documentType,
    required this.documentNumber,
    required this.phone,
    required this.email,
    required this.password,
  });

  final String fullName;
  final DocumentType documentType;
  final String documentNumber;
  final String phone;
  final String email;
  final String password;

  /// Metadatos que lee el trigger `handle_new_user` en Supabase.
  Map<String, dynamic> toMetadata() => {
    'full_name': fullName.trim(),
    'document_type': documentType.dbValue,
    'document_number': documentNumber.trim(),
    'phone': phone.trim(),
  };
}

/// Resultado del registro.
enum SignUpResult { signedIn, emailConfirmationRequired }
