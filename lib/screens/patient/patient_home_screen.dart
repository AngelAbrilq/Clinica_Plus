import 'package:material_ui/material_ui.dart';

import '../../widgets/role_home_placeholder.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const RoleHomePlaceholder(
    title: 'Mis citas',
    icon: Icons.person_rounded,
    upcomingModules: [
      'Agendar cita por síntomas',
      'Mis próximas citas y código QR de check-in',
      'Sala de espera en vivo',
      'Mi historia clínica',
    ],
  );
}
