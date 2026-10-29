import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/patient_appointment.dart';
import '../../providers/appointment_provider.dart';
import '../../utils/date_formatters.dart';
import '../../utils/specialty_icons.dart';
import '../../widgets/animations/fade_slide_in.dart';
import '../../widgets/appointment_status_chip.dart';
import '../../widgets/error_banner.dart';

/// Detalle de una cita: datos, QR de check-in y cancelación.
class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({
    super.key,
    required this.appointmentId,
    this.isNewlyBooked = false,
  });

  final int appointmentId;

  /// `true` al llegar recién agendada: muestra el mensaje de éxito.
  final bool isNewlyBooked;

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppointmentProvider>();
      if (provider.appointmentById(widget.appointmentId) == null) {
        provider.loadMyAppointments();
      }
    });
  }

  Future<void> _cancel(PatientAppointment appointment) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('El horario quedará libre para otro paciente.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancelar cita'),
          ),
        ],
      ),
    );
    final reason = reasonController.text;
    reasonController.dispose();
    if (confirmed != true || !mounted) return;

    final cancelled = await context.read<AppointmentProvider>().cancel(
      appointment,
      reason: reason,
    );
    if (cancelled && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cita cancelada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    final appointment = provider.appointmentById(widget.appointmentId);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de la cita')),
      body: appointment == null
          ? Center(
              child: provider.isLoadingAppointments
                  ? const CircularProgressIndicator()
                  : const Text('No encontramos esta cita.'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.isNewlyBooked) const _SuccessBanner(),
                if (provider.errorMessage != null)
                  ErrorBanner(
                    message: provider.errorMessage!,
                    onDismiss: provider.clearError,
                  ),
                FadeSlideIn(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                SpecialtyIcons.forName(
                                  appointment.specialtyName,
                                ),
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  appointment.specialtyName,
                                  style: theme.textTheme.titleLarge,
                                ),
                              ),
                              AppointmentStatusChip(status: appointment.status),
                            ],
                          ),
                          const Divider(height: 28),
                          if (appointment.startsAt != null) ...[
                            _InfoRow(
                              icon: Icons.event_outlined,
                              label: 'Fecha',
                              value: DateFormatters.longDate(
                                appointment.startsAt!,
                              ),
                            ),
                            _InfoRow(
                              icon: Icons.schedule_rounded,
                              label: 'Hora',
                              value: DateFormatters.timeRange(
                                appointment.startsAt!,
                                appointment.endsAt ?? appointment.startsAt!,
                              ),
                            ),
                          ],
                          _InfoRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Médico',
                            value: appointment.doctorName,
                          ),
                          _InfoRow(
                            icon: Icons.place_outlined,
                            label: 'Sede',
                            value: appointment.siteAddress.isEmpty
                                ? appointment.siteName
                                : '${appointment.siteName}\n${appointment.siteAddress}',
                          ),
                          if (appointment.symptoms != null)
                            _InfoRow(
                              icon: Icons.notes_rounded,
                              label: 'Síntomas',
                              value: appointment.symptoms!,
                            ),
                          if (appointment.cancelReason != null)
                            _InfoRow(
                              icon: Icons.info_outline_rounded,
                              label: 'Motivo de cancelación',
                              value: appointment.cancelReason!,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (appointment.isUpcoming(DateTime.now()))
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 150),
                    child: _CheckInQrCard(code: appointment.checkInCode),
                  ),
                const SizedBox(height: 12),
                if (provider.canCancel(appointment))
                  OutlinedButton.icon(
                    onPressed: provider.isSaving
                        ? null
                        : () => _cancel(appointment),
                    icon: const Icon(Icons.event_busy_outlined),
                    label: const Text('Cancelar cita'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  )
                else if (appointment.isUpcoming(DateTime.now()))
                  Text(
                    'Para cancelar con menos de 2 horas de anticipación, '
                    'comunícate con la clínica.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (_, value, child) => Transform.scale(scale: value, child: child),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: colors.primary, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '¡Cita agendada! Guarda tu código QR para el check-in.',
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckInQrCard extends StatelessWidget {
  const _CheckInQrCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Código de check-in',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Muéstralo en recepción al llegar',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Fondo blanco siempre: los lectores QR fallan con fondos oscuros.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: code,
              size: 200,
              backgroundColor: Colors.white,
              semanticsLabel: 'Código QR de check-in',
            ),
          ),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
