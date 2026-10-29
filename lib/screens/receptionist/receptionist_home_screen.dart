import 'package:material_ui/material_ui.dart';

import '../../widgets/role_home_placeholder.dart';

class ReceptionistHomeScreen extends StatelessWidget {
  const ReceptionistHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const RoleHomePlaceholder(
    title: 'Recepción',
    icon: Icons.support_agent_rounded,
    upcomingModules: [
      'Citas del día por sede',
      'Check-in con escáner QR',
      'Reasignar citas y marcar inasistencias',
    ],
  );
}
