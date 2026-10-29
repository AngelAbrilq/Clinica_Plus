import 'package:material_ui/material_ui.dart';

import '../../config/routes/app_routes.dart';
import '../../widgets/role_home_placeholder.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const RoleHomePlaceholder(
    title: 'Administración',
    icon: Icons.admin_panel_settings_rounded,
    actions: [
      HomeAction(
        title: 'Personal',
        subtitle:
            'Aprobar cuentas, asignar roles y gestionar horarios de médicos',
        icon: Icons.groups_rounded,
        route: AppRoutes.adminStaff,
      ),
    ],
    upcomingModules: [
      'Sedes y especialidades',
      'Dashboard de ocupación e inasistencias',
      'Auditoría de historias clínicas',
    ],
  );
}
