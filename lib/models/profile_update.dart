import 'document_type.dart';

/// Datos que el usuario puede editar de su propio perfil.
/// Coinciden con las columnas que la migración 001 autoriza
/// (`grant update (full_name, document_type, ...)`): rol, correo e
/// inasistencias nunca se envían desde la app.
class ProfileUpdate {
  const ProfileUpdate({
    required this.fullName,
    required this.documentType,
    required this.documentNumber,
    required this.phone,
    this.birthDate,
  });

  final String fullName;
  final DocumentType documentType;
  final String documentNumber;
  final String phone;
  final DateTime? birthDate;

  Map<String, dynamic> toJson() => {
        'full_name': fullName.trim(),
        'document_type': documentType.dbValue,
        'document_number': documentNumber.trim(),
        'phone': phone.trim(),
        'birth_date': birthDate == null
            ? null
            : '${birthDate!.year.toString().padLeft(4, '0')}-'
                '${birthDate!.month.toString().padLeft(2, '0')}-'
                '${birthDate!.day.toString().padLeft(2, '0')}',
      };
}
