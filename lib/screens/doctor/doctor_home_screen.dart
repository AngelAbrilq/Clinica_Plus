import 'package:material_ui/material_ui.dart';

import '../../models/user_role.dart';
import '../../widgets/dashboard/role_dashboard.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const RoleDashboard(
    role: UserRole.doctor,
    subtitle: 'Tu consulta de hoy',
  );
}
