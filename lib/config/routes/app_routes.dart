import '../../models/user_role.dart';

/// Rutas de la app y reglas de acceso por rol.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String pendingApproval = '/pending';
  static const String patientHome = '/patient';
  static const String patientBook = '/patient/book';
  static const String patientRecords = '/patient/records';
  static const String patientAppointments = '/patient/appointments';
  static const String patientAppointmentDetail =
      '/patient/appointments/:appointmentId';

  static String patientAppointmentDetailPath(
    int appointmentId, {
    bool isNew = false,
  }) => '/patient/appointments/$appointmentId${isNew ? '?new=1' : ''}';
  static const String doctorHome = '/doctor';
  static const String doctorAgenda = '/doctor/agenda';
  static const String doctorConsultation =
      '/doctor/consultation/:appointmentId';

  static String doctorConsultationPath(int appointmentId) =>
      '/doctor/consultation/$appointmentId';
  static const String receptionHome = '/reception';
  static const String receptionAgenda = '/reception/agenda';
  static const String receptionCheckIn = '/reception/check-in';
  static const String adminHome = '/admin';
  static const String adminStaff = '/admin/staff';
  static const String adminCatalogs = '/admin/catalogs';
  static const String adminMetrics = '/admin/metrics';
  static const String adminAudit = '/admin/audit';
  static const String adminDoctorSchedules = '/admin/doctors/:doctorId';

  static String doctorSchedulesPath(int doctorId) => '/admin/doctors/$doctorId';

  static const Set<String> publicRoutes = {login, register, forgotPassword};

  /// Rutas disponibles para cualquier usuario autenticado, sin importar su rol.
  static const String profile = '/profile';
  static const Set<String> sharedRoutes = {profile};

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
      sharedRoutes.contains(location) ||
      location == homeFor(role) ||
      location.startsWith('${homeFor(role)}/');
}
