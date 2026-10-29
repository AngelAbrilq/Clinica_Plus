import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../providers/auth_provider.dart';
import '../../screens/admin/admin_home_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/pending_approval_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/doctor/doctor_home_screen.dart';
import '../../screens/patient/patient_home_screen.dart';
import '../../screens/receptionist/receptionist_home_screen.dart';
import '../../screens/shared/splash_screen.dart';
import 'app_routes.dart';

/// Construye el router con guards de sesión y rol.
GoRouter buildAppRouter(AuthProvider auth) => GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: auth,
      redirect: (BuildContext context, GoRouterState state) =>
          _resolveRedirect(auth, state.matchedLocation),
      routes: [
        GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
        GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
        GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterScreen()),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, _) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: AppRoutes.pendingApproval,
          builder: (_, _) => const PendingApprovalScreen(),
        ),
        GoRoute(path: AppRoutes.patientHome, builder: (_, _) => const PatientHomeScreen()),
        GoRoute(path: AppRoutes.doctorHome, builder: (_, _) => const DoctorHomeScreen()),
        GoRoute(
          path: AppRoutes.receptionHome,
          builder: (_, _) => const ReceptionistHomeScreen(),
        ),
        GoRoute(path: AppRoutes.adminHome, builder: (_, _) => const AdminHomeScreen()),
      ],
    );

String? _resolveRedirect(AuthProvider auth, String location) {
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
