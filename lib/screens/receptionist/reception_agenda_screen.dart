import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../config/routes/app_routes.dart';
import '../../models/reception_appointment.dart';
import '../../providers/reception_provider.dart';
import '../../utils/app_exception.dart';
import '../../utils/date_formatters.dart';
import '../../widgets/appointment_status_chip.dart';
import '../../widgets/date_navigator.dart';
import '../../widgets/error_banner.dart';
import 'widgets/check_in_result_sheet.dart';

/// Agenda del día por sede: quién falta por llegar, quién está en sala
/// y qué citas ya se cerraron. Check-in manual e inasistencias.
class ReceptionAgendaScreen extends StatefulWidget {
  const ReceptionAgendaScreen({super.key});

  @override
  State<ReceptionAgendaScreen> createState() => _ReceptionAgendaScreenState();
}

class _ReceptionAgendaScreenState extends State<ReceptionAgendaScreen> {
  ReceptionGroup? _filter;

  /// Reconstruye cada 30 s para que "Retrasado" y los botones
  /// habilitados se actualicen solos con el paso del tiempo.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ReceptionProvider>().initialize(),
    );
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _checkIn(ReceptionAppointment appointment) async {
    final confirmed = await _confirm(
      'Registrar llegada',
      '¿${appointment.patientName} está en la sede para su cita de '
          '${DateFormatters.time(appointment.startsAt)}?',
      'Registrar llegada',
    );
    if (!confirmed || !mounted) return;
    try {
      final result = await context.read<ReceptionProvider>().checkInById(
        appointment.id,
      );
      if (mounted) await showCheckInResultSheet(context, result: result);
    } on AppException catch (error) {
      if (mounted)
        await showCheckInResultSheet(context, errorMessage: error.message);
    }
  }

  Future<void> _markNoShow(ReceptionAppointment appointment) async {
    final confirmed = await _confirm(
      'Marcar inasistencia',
      '${appointment.patientName} no llegó a su cita. Con 3 inasistencias se '
          'bloquea su agendamiento en línea por 30 días.',
      'Marcar inasistencia',
    );
    if (!confirmed || !mounted) return;
    try {
      await context.read<ReceptionProvider>().markNoShow(appointment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inasistencia registrada')),
        );
      }
    } on AppException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceptionProvider>();
    final theme = Theme.of(context);
    final now = provider.now;
    final filter = _filter;
    final items = filter == null ? provider.agenda : provider.byGroup(filter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda del día'),
        actions: [
          IconButton(
            tooltip: 'Escanear QR',
            onPressed: () => context.go(AppRoutes.receptionCheckIn),
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            if (provider.sites.length > 1)
              SegmentedButton<int>(
                segments: [
                  for (final site in provider.sites)
                    ButtonSegment(value: site.id, label: Text(site.name)),
                ],
                selected: {if (provider.siteId != null) provider.siteId!},
                onSelectionChanged: (selection) =>
                    provider.selectSite(selection.first),
              ),
            const SizedBox(height: 8),
            DateNavigator(
              date: provider.date,
              isToday: provider.isToday,
              onShift: provider.shiftDate,
              onToday: provider.goToToday,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final group in ReceptionGroup.values) ...[
                  Expanded(
                    child: _CounterTile(
                      label: group.label,
                      count: provider.countOf(group),
                      selected: _filter == group,
                      onTap: () => setState(
                        () => _filter = _filter == group ? null : group,
                      ),
                    ),
                  ),
                  if (group != ReceptionGroup.values.last)
                    const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (provider.errorMessage != null)
              ErrorBanner(
                message: provider.errorMessage!,
                onDismiss: provider.clearError,
              ),
            if (provider.isLoading && provider.agenda.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  filter == null
                      ? 'No hay citas este día en esta sede.'
                      : 'No hay citas en "${filter.label}".',
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final appointment in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AgendaRow(
                    appointment: appointment,
                    now: now,
                    isBusy: provider.isProcessing,
                    onCheckIn: () => _checkIn(appointment),
                    onNoShow: () => _markNoShow(appointment),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _CounterTile extends StatelessWidget {
  const _CounterTile({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? colors.primaryContainer
                : colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.appointment,
    required this.now,
    required this.isBusy,
    required this.onCheckIn,
    required this.onNoShow,
  });

  final ReceptionAppointment appointment;
  final DateTime now;
  final bool isBusy;
  final VoidCallback onCheckIn;
  final VoidCallback onNoShow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isLate = appointment.isRunningLate(now);

    Widget? action;
    if (appointment.canCheckIn(now)) {
      action = FilledButton.tonal(
        onPressed: isBusy ? null : onCheckIn,
        child: const Text('Llegó'),
      );
    } else if (appointment.canMarkNoShow(now)) {
      action = TextButton(
        onPressed: isBusy ? null : onNoShow,
        style: TextButton.styleFrom(foregroundColor: colors.error),
        child: const Text('No asistió'),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormatters.time(appointment.startsAt),
                    style: theme.textTheme.titleMedium,
                  ),
                  if (isLate)
                    Text(
                      'Retrasado',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.error,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.patientName,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (appointment.patientDocument != null)
                    Text(
                      appointment.patientDocument!,
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${appointment.specialtyName} con ${appointment.doctorName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppointmentStatusChip(status: appointment.status),
                ],
              ),
            ),
            if (action != null) ...[const SizedBox(width: 8), action],
          ],
        ),
      ),
    );
  }
}
