import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../config/routes/app_routes.dart';
import '../../models/doctor_appointment.dart';
import '../../providers/doctor_provider.dart';
import '../../utils/date_formatters.dart';
import '../../widgets/appointment_status_chip.dart';
import '../../widgets/date_navigator.dart';
import '../../widgets/error_banner.dart';

/// Agenda del médico agrupada por prioridad:
/// En consulta → En sala → Por llegar → Finalizadas.
class DoctorAgendaScreen extends StatefulWidget {
  const DoctorAgendaScreen({super.key});

  @override
  State<DoctorAgendaScreen> createState() => _DoctorAgendaScreenState();
}

class _DoctorAgendaScreenState extends State<DoctorAgendaScreen> {
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DoctorProvider>().loadAgenda(),
    );
    // Recepción hace check-in en otra pantalla: se refresca cada minuto
    // para que el paciente aparezca "En sala" sin recargar a mano.
    _autoRefresh = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) context.read<DoctorProvider>().loadAgenda();
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: RefreshIndicator(
        onRefresh: provider.loadAgenda,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            DateNavigator(
              date: provider.date,
              isToday: provider.isToday,
              onShift: provider.shiftDate,
              onToday: provider.goToToday,
            ),
            if (provider.errorMessage != null)
              ErrorBanner(
                message: provider.errorMessage!,
                onDismiss: provider.clearError,
              ),
            if (provider.isLoadingAgenda && provider.agenda.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.agenda.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No tienes citas este día.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final group in DoctorAgendaGroup.values)
                if (provider.byGroup(group).isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                    child: Text(
                      '${group.label} (${provider.byGroup(group).length})',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  for (final appointment in provider.byGroup(group))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AgendaTile(
                        appointment: appointment,
                        now: provider.now,
                        onTap: () => context.push(
                          AppRoutes.doctorConsultationPath(appointment.id),
                        ),
                      ),
                    ),
                ],
          ],
        ),
      ),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({
    required this.appointment,
    required this.now,
    required this.onTap,
  });

  final DoctorAppointment appointment;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final waiting = appointment.minutesWaiting(now);
    final highlighted =
        appointment.group == DoctorAgendaGroup.waiting ||
        appointment.group == DoctorAgendaGroup.inProgress;
    final age = appointment.patientAge;

    return Card(
      color: highlighted ? colors.primaryContainer : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  DateFormatters.time(appointment.startsAt),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      age == null
                          ? appointment.patientName
                          : '${appointment.patientName}, $age años',
                      style: theme.textTheme.titleMedium,
                    ),
                    if (appointment.symptoms != null)
                      Text(
                        appointment.symptoms!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        AppointmentStatusChip(status: appointment.status),
                        if (waiting != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Esperando $waiting min',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: waiting >= 15
                                  ? colors.error
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
