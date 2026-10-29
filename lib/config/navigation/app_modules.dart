import 'package:material_ui/material_ui.dart';

import '../../models/user_role.dart';
import '../constants/app_constants.dart';
import '../routes/app_routes.dart';
import 'app_module.dart';

/// Registro ÚNICO de módulos de Clinica Plus.
///
/// Para agregar un módulo nuevo:
///   1. Añade un [AppModule] aquí (con `status: ModuleStatus.comingSoon`
///      mientras se construye).
///   2. Crea su pantalla y su ruta en `app_router.dart`.
///   3. Cambia el estado a `available` (y agrega `navigationLabel` si debe
///      ir en la barra de navegación).
/// Dashboards, barra inferior y menú lateral se actualizan solos.
abstract final class AppModules {
  static const Set<UserRole> _allRoles = {...UserRole.values};

  static const List<AppModule> all = [
    // ---------------- Paciente ----------------
    AppModule(
      id: 'patient.book',
      title: 'Agendar cita',
      description: 'Elige especialidad, sede y hora disponible',
      icon: Icons.add_circle_outline_rounded,
      roles: {UserRole.patient},
      route: AppRoutes.patientBook,
    ),
    AppModule(
      id: 'patient.appointments',
      title: 'Mis citas',
      description: 'Próximas citas, código QR e historial',
      icon: Icons.event_note_outlined,
      selectedIcon: Icons.event_note_rounded,
      roles: {UserRole.patient},
      route: AppRoutes.patientAppointments,
      navigationLabel: 'Citas',
    ),
    AppModule(
      id: 'patient.symptoms',
      title: 'Asistente de síntomas',
      description: 'Te orienta sobre qué especialidad necesitas',
      icon: Icons.auto_awesome_outlined,
      roles: {UserRole.patient},
      status: ModuleStatus.comingSoon,
    ),
    AppModule(
      id: 'patient.records',
      title: 'Mi historia clínica',
      description: 'Diagnósticos y notas de tus consultas',
      icon: Icons.folder_shared_outlined,
      roles: {UserRole.patient},
      status: ModuleStatus.comingSoon,
    ),

    // ---------------- Médico ----------------
    AppModule(
      id: 'doctor.agenda',
      title: 'Agenda del día',
      description: 'Pacientes en sala y próximas consultas',
      icon: Icons.today_outlined,
      roles: {UserRole.doctor},
      status: ModuleStatus.comingSoon,
    ),
    AppModule(
      id: 'doctor.consultation',
      title: 'Atender paciente',
      description: 'Registrar motivo, notas y diagnóstico CIE-10',
      icon: Icons.medical_services_outlined,
      roles: {UserRole.doctor},
      status: ModuleStatus.comingSoon,
    ),

    // ---------------- Recepción ----------------
    AppModule(
      id: 'reception.agenda',
      title: 'Citas del día',
      description: 'Agenda por sede, reasignaciones e inasistencias',
      icon: Icons.view_agenda_outlined,
      selectedIcon: Icons.view_agenda_rounded,
      roles: {UserRole.receptionist},
      route: AppRoutes.receptionAgenda,
      navigationLabel: 'Agenda',
    ),
    AppModule(
      id: 'reception.checkin',
      title: 'Check-in con QR',
      description: 'Escanea el código del paciente al llegar',
      icon: Icons.qr_code_scanner_rounded,
      roles: {UserRole.receptionist},
      route: AppRoutes.receptionCheckIn,
      navigationLabel: 'Check-in',
    ),

    // ---------------- Administración ----------------
    AppModule(
      id: 'admin.staff',
      title: 'Personal',
      description: 'Aprobar cuentas, asignar roles y horarios de médicos',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
      roles: {UserRole.admin},
      route: AppRoutes.adminStaff,
      navigationLabel: 'Personal',
    ),
    AppModule(
      id: 'admin.catalogs',
      title: 'Sedes y especialidades',
      description: 'Direcciones, duración de consultas y estado',
      icon: Icons.apartment_outlined,
      roles: {UserRole.admin},
      status: ModuleStatus.comingSoon,
    ),
    AppModule(
      id: 'admin.metrics',
      title: 'Indicadores',
      description: 'Ocupación, cancelaciones e inasistencias',
      icon: Icons.insights_outlined,
      roles: {UserRole.admin},
      status: ModuleStatus.comingSoon,
    ),
    AppModule(
      id: 'admin.audit',
      title: 'Auditoría',
      description: 'Quién consultó o modificó historias clínicas',
      icon: Icons.policy_outlined,
      roles: {UserRole.admin},
      status: ModuleStatus.comingSoon,
    ),

    // ---------------- Todos ----------------
    AppModule(
      id: 'shared.profile',
      title: 'Mi perfil',
      description: 'Datos personales y contraseña',
      icon: Icons.manage_accounts_outlined,
      roles: _allRoles,
      status: ModuleStatus.comingSoon,
    ),
  ];

  static List<AppModule> forRole(UserRole role) =>
      all.where((module) => module.roles.contains(role)).toList();

  static List<AppModule> availableFor(UserRole role) =>
      forRole(role).where((module) => module.isAvailable).toList();

  static List<AppModule> comingSoonFor(UserRole role) =>
      forRole(role).where((module) => !module.isAvailable).toList();

  static List<AppModule> navigationFor(UserRole role) =>
      forRole(role).where((module) => module.isInNavigation).toList();

  /// Título del dashboard de cada rol.
  static String dashboardTitle(UserRole role) => switch (role) {
    UserRole.patient => AppConstants.appName,
    UserRole.doctor => 'Portal médico',
    UserRole.receptionist => 'Recepción',
    UserRole.admin => 'Administración',
  };
}
