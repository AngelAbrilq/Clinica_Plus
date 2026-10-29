import '../../models/user_role.dart';

/// Rutas de la app y reglas de acceso por rol.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String pendingApproval = '/pending';
  static const String patientHome = '/patient';
  static const String doctorHome = '/doctor';
  static const String receptionHome = '/reception';
  static const String adminHome = '/admin';

  static const Set<String> publicRoutes = {login, register, forgotPassword};

  /// Pantalla inicial según el rol (null = pendiente de aprobación).
  static String homeFor(UserRole? role) => switch (role) {
        UserRole.patient => patientHome,
        UserRole.doctor => doctorHome,
        UserRole.receptionist => receptionHome,
        UserRole.admin => adminHome,
        null => pendingApproval,
      };

  /// Un usuario solo navega dentro de la sección de su rol.
  static bool canAccess(String location, UserRole? role) =>
      location == homeFor(role) || location.startsWith('${homeFor(role)}/');
}
