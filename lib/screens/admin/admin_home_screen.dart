import 'package:material_ui/material_ui.dart';

import '../../models/user_role.dart';
import '../../widgets/dashboard/role_dashboard.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const RoleDashboard(
    role: UserRole.admin,
    subtitle: 'Gestión de la clínica',
  );
}
