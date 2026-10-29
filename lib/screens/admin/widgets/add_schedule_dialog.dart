import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../config/constants/app_constants.dart';
import '../../../models/doctor_schedule.dart';
import '../../../providers/admin_provider.dart';

/// Pide sede, día y franja horaria. Devuelve `null` si se cancela.
Future<NewDoctorSchedule?> showAddScheduleDialog(
  BuildContext context, {
  required int doctorId,
}) =>
    showDialog<NewDoctorSchedule>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AdminProvider>(),
        child: _AddScheduleDialog(doctorId: doctorId),
      ),
    );

class _AddScheduleDialog extends StatefulWidget {
  const _AddScheduleDialog({required this.doctorId});

  final int doctorId;

  @override
  State<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<_AddScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _siteId;
  int _weekday = 1;
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 12, minute: 0);
  String? _timeError;

  static int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  static String _format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      helpText: isStart ? 'Hora de inicio' : 'Hora de fin',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
      _timeError = null;
    });
  }

  void _submit() {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (_toMinutes(_end) <= _toMinutes(_start)) {
      setState(() => _timeError = 'La hora de fin debe ser posterior a la de inicio');
      return;
    }
    if (!isFormValid) return;
    Navigator.of(context).pop(
      NewDoctorSchedule(
        doctorId: widget.doctorId,
        siteId: _siteId!,
        weekday: _weekday,
        startTime: _format(_start),
        endTime: _format(_end),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sites = context.watch<AdminProvider>().sites;
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Nuevo horario'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _siteId,
                decoration: const InputDecoration(labelText: 'Sede'),
                items: [
                  for (final site in sites)
                    DropdownMenuItem(value: site.id, child: Text(site.name)),
                ],
                validator: (value) => value == null ? 'Elige una sede' : null,
                onChanged: (value) => setState(() => _siteId = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _weekday,
                decoration: const InputDecoration(labelText: 'Día'),
                items: [
                  for (final entry in AppConstants.weekdayLabels.entries)
                    DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                ],
                onChanged: (value) => setState(() => _weekday = value ?? _weekday),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(isStart: true),
                      icon: const Icon(Icons.login_rounded),
                      label: Text('Desde ${_format(_start)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(isStart: false),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text('Hasta ${_format(_end)}'),
                    ),
                  ),
                ],
              ),
              if (_timeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_timeError!, style: TextStyle(color: colors.error)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Agregar')),
      ],
    );
  }
}
