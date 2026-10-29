import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/patient_sign_up_data.dart';
import '../../models/user_profile.dart';
import '../../utils/app_exception.dart';
import 'auth_repository.dart';

/// Implementación de [AuthRepository] con Supabase Auth + tabla `profiles`.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  static const Set<AuthChangeEvent> _relevantEvents = {
    AuthChangeEvent.signedIn,
    AuthChangeEvent.signedOut,
    AuthChangeEvent.userUpdated,
  };

  @override
  Stream<void> get sessionChanges => _client.auth.onAuthStateChange
      .where((state) => _relevantEvents.contains(state.event));

  @override
  bool get isSignedIn => _client.auth.currentSession != null;

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(() => _client.auth.signInWithPassword(email: email, password: password));

  @override
  Future<SignUpResult> signUpPatient(PatientSignUpData data) => _guard(() async {
        final response = await _client.auth.signUp(
          email: data.email.trim(),
          password: data.password,
          data: data.toMetadata(),
        );
        return response.session == null
            ? SignUpResult.emailConfirmationRequired
            : SignUpResult.signedIn;
      });

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _client.auth.resetPasswordForEmail(email.trim()));

  @override
  Future<void> signOut() => _guard(() => _client.auth.signOut());

  @override
  Future<UserProfile?> fetchCurrentProfile() => _guard(() async {
        final userId = _client.auth.currentUser?.id;
        if (userId == null) return null;
        final row = await _client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        return row == null ? null : UserProfile.fromJson(row);
      });

  /// Ejecuta [action] traduciendo errores técnicos a [AppException].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException catch (error) {
      _logDebug('AuthException code=${error.code} status=${error.statusCode} msg=${error.message}');
      throw AppException(_authMessage(error), cause: error);
    } on PostgrestException catch (error) {
      _logDebug('PostgrestException code=${error.code} msg=${error.message} details=${error.details}');
      throw AppException('No pudimos cargar tus datos. Intenta de nuevo.', cause: error);
    } catch (error) {
      _logDebug('Unexpected error: $error');
      throw AppException(
        'Ocurrió un error inesperado. Revisa tu conexión e inténtalo de nuevo.',
        cause: error,
      );
    }
  }

  /// Solo en modo debug; nunca se imprime en builds de producción.
  void _logDebug(String message) {
    if (kDebugMode) debugPrint('[Auth] $message');
  }

  String _authMessage(AuthException error) {
    final code = error.code ?? '';
    final message = error.message.toLowerCase();
    if (code == 'invalid_credentials' || message.contains('invalid login')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (code == 'email_not_confirmed' || message.contains('not confirmed')) {
      return 'Confirma tu correo antes de iniciar sesión. Revisa tu bandeja de entrada.';
    }
    if (code == 'user_already_exists' || message.contains('already registered')) {
      return 'Ya existe una cuenta con este correo.';
    }
    if (code.contains('rate_limit') || error.statusCode == '429') {
      return 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
    }
    if (code == 'weak_password') {
      return 'La contraseña es muy débil. Usa letras, números y al menos 8 caracteres.';
    }
    if (message.contains('database error saving new user')) {
      return 'No se pudo crear la cuenta. Verifica que tu documento no esté ya registrado.';
    }
    return 'No pudimos completar la operación. Intenta de nuevo.';
  }
}
