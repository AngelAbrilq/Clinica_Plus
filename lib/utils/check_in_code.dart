/// Formato del QR de check-in: `clinicaplus:checkin:<uuid>`.
/// Lo genera la app del paciente y lo lee la de recepción: al vivir en un
/// solo lugar, ambos lados nunca se desincronizan.
abstract final class CheckInCode {
  static const String _prefix = 'clinicaplus:checkin:';
  static final RegExp _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static String build(String token) => '$_prefix$token';

  /// Devuelve el token si [raw] es un código válido de Clinica Plus.
  /// Acepta también el token solo (para escribirlo a mano).
  static String? parse(String raw) {
    final value = raw.trim();
    final token = value.startsWith(_prefix)
        ? value.substring(_prefix.length)
        : value;
    return _uuid.hasMatch(token) ? token.toLowerCase() : null;
  }
}
