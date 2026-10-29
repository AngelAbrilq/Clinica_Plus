import 'package:material_ui/material_ui.dart';

import '../../widgets/role_home_placeholder.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const RoleHomePlaceholder(
        title: 'Administración',
        icon: Icons.admin_panel_settings_rounded,
        upcomingModules: [
          'Aprobar personal y asignar roles',
          'Médicos, horarios y sedes',
          'Dashboard de ocupación e inasistencias',
          'Auditoría de historias clínicas',
        ],
      );
}
