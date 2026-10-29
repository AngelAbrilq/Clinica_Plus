import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../providers/app_startup_notifier.dart';
import '../../providers/auth_provider.dart';
import '../../screens/admin/admin_home_screen.dart';
import '../../screens/admin/doctor_schedules_screen.dart';
import '../../screens/admin/staff_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/pending_approval_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/doctor/doctor_home_screen.dart';
import '../../screens/patient/patient_home_screen.dart';
import '../../screens/receptionist/receptionist_home_screen.dart';
import '../../screens/shared/splash_screen.dart';
import 'app_routes.dart';

/// Construye el router con guards de intro, sesión y rol.
GoRouter buildAppRouter({
  required AuthProvider auth,
  required AppStartupNotifier startup,
}) => GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: Listenable.merge([auth, startup]),
  redirect: (BuildContext context, GoRouterState state) =>
      _resolveRedirect(auth, startup, state.matchedLocation),
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (_, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const SplashScreen(),
      ),
    ),
    _animatedRoute(AppRoutes.login, (_) => const LoginScreen()),
    _animatedRoute(AppRoutes.register, (_) => const RegisterScreen()),
    _animatedRoute(
      AppRoutes.forgotPassword,
      (_) => const ForgotPasswordScreen(),
    ),
    _animatedRoute(
      AppRoutes.pendingApproval,
      (_) => const PendingApprovalScreen(),
    ),
    _animatedRoute(AppRoutes.patientHome, (_) => const PatientHomeScreen()),
    _animatedRoute(AppRoutes.doctorHome, (_) => const DoctorHomeScreen()),
    _animatedRoute(
      AppRoutes.receptionHome,
      (_) => const ReceptionistHomeScreen(),
    ),
    _animatedRoute(AppRoutes.adminHome, (_) => const AdminHomeScreen()),
    _animatedRoute(AppRoutes.adminStaff, (_) => const StaffScreen()),
    _animatedRoute(AppRoutes.adminDoctorSchedules, (state) {
      final doctorId = int.tryParse(state.pathParameters['doctorId'] ?? '');
      return doctorId == null
          ? const StaffScreen()
          : DoctorSchedulesScreen(doctorId: doctorId);
    }),
  ],
);

/// Ruta con transición: la pantalla nueva sube levemente mientras aparece,
/// y la anterior se desvanece hacia atrás (estilo apps nativas modernas).
GoRoute _animatedRoute(
  String path,
  Widget Function(GoRouterState state) builder,
) => GoRoute(
  path: path,
  pageBuilder: (_, state) => CustomTransitionPage<void>(
    key: state.pageKey,
    child: builder(state),
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final enter = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final exit = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: enter,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(enter),
          child: FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.6).animate(exit),
            child: ScaleTransition(
              scale: Tween(begin: 1.0, end: 0.96).animate(exit),
              child: child,
            ),
          ),
        ),
      );
    },
  ),
);

String? _resolveRedirect(
  AuthProvider auth,
  AppStartupNotifier startup,
  String location,
) {
  // La intro se muestra completa antes de cualquier otra pantalla.
  if (!startup.introCompleted) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  final isPublic = AppRoutes.publicRoutes.contains(location);
  switch (auth.status) {
    case AuthStatus.unknown:
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case AuthStatus.unauthenticated:
      return isPublic ? null : AppRoutes.login;
    case AuthStatus.authenticated:
      final role = auth.profile?.role;
      final home = AppRoutes.homeFor(role);
      if (isPublic || location == AppRoutes.splash) return home;
      return AppRoutes.canAccess(location, role) ? null : home;
  }
}
