import 'package:material_ui/material_ui.dart';

import '../../models/user_role.dart';
import '../../widgets/dashboard/role_dashboard.dart';

class ReceptionistHomeScreen extends StatelessWidget {
  const ReceptionistHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const RoleDashboard(
    role: UserRole.receptionist,
    subtitle: 'Recepción de pacientes',
  );
}
