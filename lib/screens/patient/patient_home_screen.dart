import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../config/constants/app_constants.dart';
import '../../config/routes/app_routes.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/animations/fade_slide_in.dart';
import 'widgets/turn_ticket.dart';

/// Home del paciente. Protagonista: el ticket del próximo turno.
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

  static String _greeting(DateTime now) => switch (now.hour) {
    < 12 => 'Buenos días',
    < 19 => 'Buenas tardes',
    _ => 'Buenas noches',
  };

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appointments = context.watch<AppointmentProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final upcoming = appointments.upcoming;
    final nextTurn = upcoming.isEmpty ? null : upcoming.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: auth.isBusy
                ? null
                : () => context.read<AuthProvider>().signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: appointments.loadMyAppointments,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              '${_greeting(DateTime.now())}, ${auth.profile?.firstName ?? ''}',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '¿Qué necesitas hoy?',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child:
                  appointments.isLoadingAppointments &&
                      appointments.appointments.isEmpty
                  ? const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : nextTurn == null
                  ? EmptyTurnTicket(
                      onBook: () => context.push(AppRoutes.patientBook),
                    )
                  : FadeSlideIn(
                      key: ValueKey(nextTurn.id),
                      child: TurnTicket(
                        appointment: nextTurn,
                        onTap: () => context.push(
                          AppRoutes.patientAppointmentDetailPath(nextTurn.id),
                        ),
                      ),
                    ),
            ),
            if (nextTurn != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.patientBook),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agendar otra cita'),
              ),
            ],
            const SizedBox(height: 28),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.event_note_rounded,
                      color: colors.primary,
                    ),
                    title: const Text('Mis citas'),
                    subtitle: Text(
                      upcoming.isEmpty
                          ? 'Historial y cancelaciones'
                          : upcoming.length == 1
                          ? '1 cita próxima'
                          : '${upcoming.length} citas próximas',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.patientAppointments),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  const ListTile(
                    enabled: false,
                    leading: Icon(Icons.folder_shared_outlined),
                    title: Text('Mi historia clínica'),
                    subtitle: Text('Disponible pronto'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.emergency_outlined, size: 18, color: colors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'En una emergencia marca ${AppConstants.emergencyPhone} o ve a urgencias.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
