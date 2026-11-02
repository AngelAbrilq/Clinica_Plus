import 'package:material_ui/material_ui.dart';

import '../models/appointment_status.dart';

/// Etiqueta de color según el estado de la cita.
class AppointmentStatusChip extends StatelessWidget {
  const AppointmentStatusChip({super.key, required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      AppointmentStatus.assigned ||
      AppointmentStatus.confirmed ||
      AppointmentStatus.requested => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      AppointmentStatus.checkedIn || AppointmentStatus.inProgress => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      AppointmentStatus.completed => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      AppointmentStatus.cancelled || AppointmentStatus.noShow => (
        colors.errorContainer,
        colors.onErrorContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
