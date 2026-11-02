import 'dart:async';

import 'package:clinica_plus/data/repositories/auth_repository.dart';
import 'package:clinica_plus/models/document_type.dart';
import 'package:clinica_plus/models/patient_sign_up_data.dart';
import 'package:clinica_plus/models/profile_update.dart';
import 'package:clinica_plus/models/user_profile.dart';
import 'package:clinica_plus/models/user_role.dart';
import 'package:clinica_plus/providers/auth_provider.dart';
import 'package:clinica_plus/utils/app_exception.dart';
import 'package:clinica_plus/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

const UserProfile _profile = UserProfile(
  id: 'u-1',
  email: 'ana@gmail.com',
  fullName: 'Ana Gómez',
  role: UserRole.patient,
);

/// Repositorio falso: sesión iniciada con [_profile].
class FakeAuthRepository implements AuthRepository {
  final StreamController<void> _changes = StreamController<void>.broadcast();
  ProfileUpdate? lastUpdate;
  AppException? nextError;
  String? newPassword;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
  }

  @override
  Stream<void> get sessionChanges => _changes.stream;

  @override
  bool get isSignedIn => true;

  @override
  Future<UserProfile?> fetchCurrentProfile() async => _profile;

  @override
  Future<UserProfile> updateProfile(ProfileUpdate update) async {
    _throwIfNeeded();
    lastUpdate = update;
    return UserProfile(
      id: _profile.id,
      email: _profile.email,
      fullName: update.fullName.trim(),
      role: _profile.role,
      documentType: update.documentType,
      documentNumber: update.documentNumber,
      phone: update.phone,
      birthDate: update.birthDate,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _throwIfNeeded();
    this.newPassword = newPassword;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<SignUpResult> signUpPatient(PatientSignUpData data) async => SignUpResult.signedIn;

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {}
}

ProfileUpdate _update({DateTime? birthDate}) => ProfileUpdate(
      fullName: '  Ana María Gómez ',
      documentType: DocumentType.cc,
      documentNumber: ' 1075123456 ',
      phone: '3001234567',
      birthDate: birthDate,
    );

void main() {
  group('ProfileUpdate.toJson', () {
    test('solo envía columnas editables, recortadas', () {
      final json = _update(birthDate: DateTime(1990, 5, 7)).toJson();
      expect(json.keys, unorderedEquals([
        'full_name',
        'document_type',
        'document_number',
        'phone',
        'birth_date',
      ]));
      expect(json['full_name'], 'Ana María Gómez');
      expect(json['document_type'], 'CC');
      expect(json['document_number'], '1075123456');
      expect(json['birth_date'], '1990-05-07');
    });

    test('fecha vacía se envía como null', () {
      expect(_update().toJson()['birth_date'], isNull);
    });
  });

  group('Validators.birthDate', () {
    final now = DateTime(2026, 11, 2);

    test('acepta vacío y fechas razonables', () {
      expect(Validators.birthDate(null, now: now), isNull);
      expect(Validators.birthDate(DateTime(1990, 1, 1), now: now), isNull);
    });

    test('rechaza fechas futuras y de hace más de 120 años', () {
      expect(Validators.birthDate(DateTime(2027, 1, 1), now: now), isNotNull);
      expect(Validators.birthDate(DateTime(1900, 1, 1), now: now), isNotNull);
    });
  });

  group('AuthProvider (perfil)', () {
    late FakeAuthRepository repository;
    late AuthProvider provider;

    setUp(() async {
      repository = FakeAuthRepository();
      provider = AuthProvider(repository);
      await Future<void>.delayed(Duration.zero); // deja terminar _syncSession
    });

    test('updateProfile reemplaza el perfil en memoria', () async {
      final saved = await provider.updateProfile(_update());
      expect(saved, isTrue);
      expect(provider.profile?.fullName, 'Ana María Gómez');
      expect(provider.isBusy, isFalse);
    });

    test('un documento duplicado deja el perfil intacto y muestra el error', () async {
      repository.nextError = const AppException('Ese documento ya está registrado en otra cuenta.');
      final saved = await provider.updateProfile(_update());
      expect(saved, isFalse);
      expect(provider.profile?.fullName, 'Ana Gómez');
      expect(provider.errorMessage, contains('documento'));
    });

    test('changePassword exitoso', () async {
      final changed = await provider.changePassword(
        currentPassword: 'vieja123',
        newPassword: 'nueva1234',
      );
      expect(changed, isTrue);
      expect(repository.newPassword, 'nueva1234');
    });

    test('contraseña actual incorrecta devuelve false', () async {
      repository.nextError = const AppException('La contraseña actual no es correcta.');
      final changed = await provider.changePassword(
        currentPassword: 'mala',
        newPassword: 'nueva1234',
      );
      expect(changed, isFalse);
      expect(provider.errorMessage, 'La contraseña actual no es correcta.');
    });
  });
}
