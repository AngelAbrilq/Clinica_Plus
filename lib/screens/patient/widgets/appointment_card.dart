import 'package:material_ui/material_ui.dart';

import '../../../models/patient_appointment.dart';
import '../../../utils/date_formatters.dart';
import '../../../utils/specialty_icons.dart';
import '../../../widgets/appointment_status_chip.dart';

/// Tarjeta de cita con bloque de fecha a la izquierda.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({super.key, required this.appointment, required this.onTap});

  final PatientAppointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final startsAt = appointment.startsAt;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      startsAt == null ? '--' : '${startsAt.day}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      startsAt == null ? '' : DateFormatters.monthShort(startsAt).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(color: colors.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(SpecialtyIcons.forName(appointment.specialtyName),
                            size: 18, color: colors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            appointment.specialtyName,
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      startsAt == null
                          ? 'Sin hora asignada'
                          : '${DateFormatters.weekdayShort(startsAt)} · ${DateFormatters.time(startsAt)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '${appointment.doctorName} · ${appointment.siteName}',
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppointmentStatusChip(status: appointment.status),
            ],
          ),
        ),
      ),
    );
  }
}
