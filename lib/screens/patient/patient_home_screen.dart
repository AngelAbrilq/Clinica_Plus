import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../config/constants/app_constants.dart';
import '../../config/routes/app_routes.dart';
import '../../models/user_role.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/animations/fade_slide_in.dart';
import '../../widgets/dashboard/role_dashboard.dart';
import 'widgets/turn_ticket.dart';

/// Home del paciente = dashboard genérico + ticket del próximo turno.
class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AppointmentProvider>().loadMyAppointments(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<AppointmentProvider>();
    return RoleDashboard(
      role: UserRole.patient,
      subtitle: '¿Qué necesitas hoy?',
      onRefresh: appointments.loadMyAppointments,
      hero: _NextTurn(provider: appointments),
      footer: const _EmergencyFooter(),
    );
  }
}

class _NextTurn extends StatelessWidget {
  const _NextTurn({required this.provider});

  final AppointmentProvider provider;

  @override
  Widget build(BuildContext context) {
    final upcoming = provider.upcoming;
    final nextTurn = upcoming.isEmpty ? null : upcoming.first;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: provider.isLoadingAppointments && provider.appointments.isEmpty
          ? const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            )
          : nextTurn == null
          ? EmptyTurnTicket(onBook: () => context.push(AppRoutes.patientBook))
          : FadeSlideIn(
              key: ValueKey(nextTurn.id),
              child: TurnTicket(
                appointment: nextTurn,
                onTap: () => context.push(
                  AppRoutes.patientAppointmentDetailPath(nextTurn.id),
                ),
              ),
            ),
    );
  }
}

class _EmergencyFooter extends StatelessWidget {
  const _EmergencyFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.emergency_outlined,
          size: 18,
          color: theme.colorScheme.error,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'En una emergencia marca ${AppConstants.emergencyPhone} o ve a urgencias.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
