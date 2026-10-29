import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/app_exception.dart';

/// Traduce errores de PostgREST/Postgres a mensajes para el usuario.
abstract final class SupabaseErrorMapper {
  /// Códigos SQLSTATE cuyo mensaje lo escribimos nosotros en las funciones
  /// SQL (raise exception) y por eso ya viene en español.
  static const Set<String> _customMessageCodes = {'42501', '22023', 'P0001', 'P0002'};

  /// Ejecuta [action]. [messagesByCode] permite mensajes según el contexto
  /// (ej. '23P01' → "El horario se cruza con otro").
  static Future<T> guard<T>(
    Future<T> Function() action, {
    Map<String, String> messagesByCode = const {},
  }) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[DB] code=${error.code} msg=${error.message} details=${error.details}',
        );
      }
      throw AppException(_messageFor(error, messagesByCode), cause: error);
    } on AppException {
      rethrow;
    } catch (error) {
      if (kDebugMode) debugPrint('[DB] unexpected: $error');
      throw AppException(
        'Ocurrió un error inesperado. Revisa tu conexión e inténtalo de nuevo.',
        cause: error,
      );
    }
  }

  static String _messageFor(
    PostgrestException error,
    Map<String, String> custom,
  ) {
    final code = error.code ?? '';
    if (custom.containsKey(code)) return custom[code]!;
    if (error.message.contains('row-level security')) {
      return 'No tienes permiso para realizar esta acción.';
    }
    if (_customMessageCodes.contains(code)) return error.message;
    return switch (code) {
      '23505' => 'Ese registro ya existe.',
      '23P01' => 'Se cruza con un registro existente.',
      '23503' => 'Hay datos relacionados que impiden esta acción.',
      '23514' => 'Alguno de los datos no tiene un formato válido.',
      _ => 'No pudimos completar la operación. Intenta de nuevo.',
    };
  }
}
