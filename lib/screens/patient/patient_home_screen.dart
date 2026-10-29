import 'package:material_ui/material_ui.dart';

import '../../config/routes/app_routes.dart';
import '../../widgets/role_home_placeholder.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const RoleHomePlaceholder(
    title: 'Clinica Plus',
    icon: Icons.person_rounded,
    actions: [
      HomeAction(
        title: 'Agendar cita',
        subtitle: 'Elige especialidad, sede y hora disponible',
        icon: Icons.add_circle_outline_rounded,
        route: AppRoutes.patientBook,
      ),
      HomeAction(
        title: 'Mis citas',
        subtitle: 'Próximas citas, código QR e historial',
        icon: Icons.event_note_rounded,
        route: AppRoutes.patientAppointments,
      ),
    ],
    upcomingModules: [
      'Asistente de síntomas con IA',
      'Sala de espera en vivo',
      'Mi historia clínica',
    ],
  );
}
