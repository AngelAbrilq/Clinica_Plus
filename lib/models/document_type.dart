/// Tipos de documento de identidad en Colombia.
/// [dbValue] coincide con el enum `document_type` de Supabase.
enum DocumentType {
  cc('CC', 'Cédula de ciudadanía'),
  ti('TI', 'Tarjeta de identidad'),
  ce('CE', 'Cédula de extranjería'),
  pa('PA', 'Pasaporte'),
  rc('RC', 'Registro civil');

  const DocumentType(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static DocumentType? tryParse(String? value) {
    for (final type in DocumentType.values) {
      if (type.dbValue == value) return type;
    }
    return null;
  }
}
