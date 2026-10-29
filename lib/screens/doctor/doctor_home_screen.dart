import 'package:material_ui/material_ui.dart';

import '../../widgets/role_home_placeholder.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const RoleHomePlaceholder(
    title: 'Portal médico',
    icon: Icons.medical_services_rounded,
    upcomingModules: [
      'Agenda del día',
      'Atender paciente y registrar diagnóstico (CIE-10)',
      'Historias clínicas de mis pacientes',
    ],
  );
}
