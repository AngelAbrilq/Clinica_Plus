import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../config/constants/app_constants.dart';
import '../../models/doctor_schedule.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/error_banner.dart';
import 'widgets/add_schedule_dialog.dart';

/// Horarios semanales de un médico: listar, agregar y eliminar.
class DoctorSchedulesScreen extends StatefulWidget {
  const DoctorSchedulesScreen({super.key, required this.doctorId});

  final int doctorId;

  @override
  State<DoctorSchedulesScreen> createState() => _DoctorSchedulesScreenState();
}

class _DoctorSchedulesScreenState extends State<DoctorSchedulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.loadSchedules(widget.doctorId);
      // Si se entra por URL directa, el personal aún no está cargado.
      if (admin.staff.isEmpty) admin.loadStaff();
    });
  }

  Future<void> _addSchedule() async {
    final schedule = await showAddScheduleDialog(context, doctorId: widget.doctorId);
    if (schedule == null || !mounted) return;
    final saved = await context.read<AdminProvider>().addSchedule(schedule);
    if (saved && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Horario agregado')));
    }
  }

  Future<void> _confirmDelete(DoctorSchedule schedule) async {
    final dayLabel = AppConstants.weekdayLabels[schedule.weekday] ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar horario'),
        content: Text(
          '¿Eliminar $dayLabel ${schedule.startTime}–${schedule.endTime} '
          'en ${schedule.siteName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AdminProvider>().deleteSchedule(schedule);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    final member = admin.doctorById(widget.doctorId);
    final doctor = member?.doctor;

    return Scaffold(
      appBar: AppBar(title: const Text('Horarios del médico')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: admin.isSaving ? null : _addSchedule,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar horario'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          if (member != null && doctor != null)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.medical_services_rounded)),
                title: Text(member.displayName),
                subtitle: Text('${doctor.specialtyName} · RM ${doctor.licenseNumber}'),
              ),
            ),
          const SizedBox(height: 12),
          if (admin.errorMessage != null)
            ErrorBanner(message: admin.errorMessage!, onDismiss: admin.clearError),
          if (admin.isLoading && admin.schedules.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (admin.schedules.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Este médico aún no tiene horarios.\n'
                'Sin horarios no se le pueden asignar citas.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            )
          else
            for (final entry in AppConstants.weekdayLabels.entries)
              ..._buildDay(entry.key, entry.value, admin.schedules, theme),
        ],
      ),
    );
  }

  List<Widget> _buildDay(
    int weekday,
    String label,
    List<DoctorSchedule> schedules,
    ThemeData theme,
  ) {
    final daySchedules = schedules.where((item) => item.weekday == weekday).toList();
    if (daySchedules.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
        child: Text(label, style: theme.textTheme.titleSmall),
      ),
      for (final schedule in daySchedules)
        Card(
          child: ListTile(
            leading: const Icon(Icons.schedule_rounded),
            title: Text('${schedule.startTime} – ${schedule.endTime}'),
            subtitle: Text(schedule.siteName),
            trailing: IconButton(
              tooltip: 'Eliminar horario',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _confirmDelete(schedule),
            ),
          ),
        ),
    ];
  }
}
