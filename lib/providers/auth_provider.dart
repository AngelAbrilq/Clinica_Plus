import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/auth_repository.dart';
import '../models/patient_sign_up_data.dart';
import '../models/user_profile.dart';
import '../utils/app_exception.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// Estado global de autenticación. go_router lo escucha
/// (refreshListenable) para redirigir según sesión y rol.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository) {
    _sessionSubscription = _repository.sessionChanges.listen((_) => _syncSession());
    _syncSession();
  }

  final AuthRepository _repository;
  late final StreamSubscription<void> _sessionSubscription;

  AuthStatus _status = AuthStatus.unknown;
  UserProfile? _profile;
  bool _isBusy = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserProfile? get profile => _profile;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  /// Inicia sesión. Devuelve `true` si las credenciales fueron aceptadas.
  Future<bool> signIn({required String email, required String password}) async {
    final result = await _run(() async {
      await _repository.signIn(email: email.trim(), password: password);
      return true;
    });
    return result ?? false;
  }

  /// Registra un paciente. `null` si falló (ver [errorMessage]).
  Future<SignUpResult?> signUpPatient(PatientSignUpData data) =>
      _run(() => _repository.signUpPatient(data));

  Future<bool> sendPasswordReset(String email) async {
    final result = await _run(() async {
      await _repository.sendPasswordReset(email);
      return true;
    });
    return result ?? false;
  }

  Future<void> signOut() async {
    await _run(_repository.signOut);
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Sincroniza estado con la sesión actual y carga el perfil.
  Future<void> _syncSession() async {
    if (!_repository.isSignedIn) {
      _profile = null;
      _setStatus(AuthStatus.unauthenticated);
      return;
    }
    try {
      final profile = await _repository.fetchCurrentProfile();
      if (profile == null) {
        throw const AppException('No encontramos tu perfil. Contacta a la clínica.');
      }
      _profile = profile;
      _setStatus(AuthStatus.authenticated);
    } on AppException catch (error) {
      _errorMessage = error.message;
      _profile = null;
      _setStatus(AuthStatus.unauthenticated);
      await _repository.signOut().catchError((_) {});
    }
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await action();
    } on AppException catch (error) {
      _errorMessage = error.message;
      return null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionSubscription.cancel();
    super.dispose();
  }
}
