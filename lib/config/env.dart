/// Variables de entorno inyectadas en compilación con
/// `--dart-define-from-file=env.json`. Nunca se versionan.
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String staffEmailDomain = String.fromEnvironment(
    'STAFF_EMAIL_DOMAIN',
    defaultValue: 'clinicaplus.co',
  );

  /// Lanza un error claro si faltan variables obligatorias.
  static void validate() {
    final missing = <String>[
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'Faltan variables de entorno: ${missing.join(', ')}. '
        'Ejecuta con --dart-define-from-file=env.json',
      );
    }
    final uri = Uri.tryParse(supabaseUrl);
    final isValidUrl = uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        (uri.path.isEmpty || uri.path == '/');
    if (!isValidUrl) {
      throw StateError(
        'SUPABASE_URL inválida: "$supabaseUrl". '
        'Debe ser https://TU-PROYECTO.supabase.co (sin rutas como /rest/v1).',
      );
    }
  }
}
