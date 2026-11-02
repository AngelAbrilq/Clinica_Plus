import '../../models/patient_sign_up_data.dart';
import '../../models/profile_update.dart';
import '../../models/user_profile.dart';

/// Contrato de autenticación. Los providers dependen de esta abstracción,
/// no de Supabase (DIP), lo que permite mockearla en tests.
abstract interface class AuthRepository {
  /// Emite cuando cambia la sesión (login, logout, usuario actualizado).
  Stream<void> get sessionChanges;

  bool get isSignedIn;

  Future<void> signIn({required String email, required String password});

  Future<SignUpResult> signUpPatient(PatientSignUpData data);

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  /// Perfil del usuario autenticado o `null` si no hay sesión.
  Future<UserProfile?> fetchCurrentProfile();

  /// Guarda los datos editables del perfil propio y devuelve el perfil actualizado.
  Future<UserProfile> updateProfile(ProfileUpdate update);

  /// Verifica la contraseña actual y la reemplaza por [newPassword].
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
