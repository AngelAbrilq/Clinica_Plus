import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/cie10_entry.dart';
import '../../models/doctor_appointment.dart';
import '../../providers/doctor_provider.dart';
import '../../utils/date_formatters.dart';
import '../../widgets/appointment_status_chip.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/medical_record_tile.dart';
import 'widgets/cie10_picker.dart';

/// Consulta: datos del paciente → iniciar → registrar → finalizar.
class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key, required this.appointmentId});

  final int appointmentId;

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  Cie10Entry? _diagnosis;
  bool _diagnosisMissing = false;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) =>
          context.read<DoctorProvider>().openConsultation(widget.appointmentId),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// El motivo arranca con lo que el paciente escribió al agendar.
  void _prefillOnce(ConsultationDetail consultation) {
    if (_prefilled) return;
    _prefilled = true;
    _reasonController.text = consultation.reason ?? consultation.symptoms ?? '';
    _notesController.text = consultation.clinicalNotes ?? '';
  }

  Future<void> _finish() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    setState(() => _diagnosisMissing = _diagnosis == null);
    if (!isValid || _diagnosis == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finalizar consulta'),
        content: Text(
          'Se guardará en la historia clínica con el diagnóstico '
          '${_diagnosis!.code}. Después no podrás editarlo desde la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Revisar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Finalizar y guardar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final saved = await context.read<DoctorProvider>().completeConsultation(
      ConsultationNote(
        reason: _reasonController.text.trim(),
        clinicalNotes: _notesController.text.trim(),
        diagnosisCode: _diagnosis!.code,
        diagnosisDescription: _diagnosis!.description,
      ),
    );
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Consulta finalizada y guardada en la historia clínica',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorProvider>();
    final consultation = provider.consultation;
    final theme = Theme.of(context);

    if (consultation == null || consultation.id != widget.appointmentId) {
      return Scaffold(
        appBar: AppBar(title: const Text('Consulta')),
        body: Center(
          child: provider.isLoadingConsultation
              ? const CircularProgressIndicator()
              : Text(provider.errorMessage ?? 'No encontramos esta cita.'),
        ),
      );
    }
    if (consultation.isInProgress) _prefillOnce(consultation);

    return Scaffold(
      appBar: AppBar(title: const Text('Consulta')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _PatientHeader(consultation: consultation),
          const SizedBox(height: 16),
          if (provider.errorMessage != null)
            ErrorBanner(
              message: provider.errorMessage!,
              onDismiss: provider.clearError,
            ),
          if (consultation.canStart)
            LoadingButton(
              label: 'Iniciar consulta',
              isLoading: provider.isSaving,
              onPressed: () =>
                  context.read<DoctorProvider>().startConsultation(),
            )
          else if (consultation.isInProgress)
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Registro de la consulta',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    minLines: 2,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Motivo de consulta',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'El motivo es obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 8,
                    minLines: 4,
                    maxLength: 10000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Notas clínicas',
                      hintText:
                          'Examen físico, signos vitales, plan de manejo…',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Cie10Picker(
                    selected: _diagnosis,
                    onChanged: (entry) => setState(() {
                      _diagnosis = entry;
                      if (entry != null) _diagnosisMissing = false;
                    }),
                  ),
                  if (_diagnosisMissing)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 12),
                      child: Text(
                        'Selecciona un diagnóstico',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  LoadingButton(
                    label: 'Finalizar consulta',
                    isLoading: provider.isSaving,
                    onPressed: _finish,
                  ),
                ],
              ),
            )
          else if (consultation.isCompleted)
            _CompletedRecord(consultation: consultation)
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.hourglass_empty_rounded),
                title: const Text('El paciente aún no está en sala'),
                subtitle: const Text(
                  'Podrás iniciar la consulta cuando recepción registre su llegada.',
                ),
              ),
            ),
          const SizedBox(height: 28),
          _HistorySection(provider: provider),
        ],
      ),
    );
  }
}

class _PatientHeader extends StatelessWidget {
  const _PatientHeader({required this.consultation});

  final ConsultationDetail consultation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final age = consultation.patientAge;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    consultation.patientName,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                AppointmentStatusChip(status: consultation.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (age != null) '$age años',
                if (consultation.patientDocument != null)
                  consultation.patientDocument!,
              ].join(', '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${consultation.specialtyName}, ${DateFormatters.time(consultation.startsAt)} '
              'en ${consultation.siteName}',
            ),
            if (consultation.symptoms != null) ...[
              const Divider(height: 24),
              Text(
                'Lo que reportó al agendar',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(consultation.symptoms!),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompletedRecord extends StatelessWidget {
  const _CompletedRecord({required this.consultation});

  final ConsultationDetail consultation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_rounded, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text('Consulta finalizada', style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(height: 24),
            Text('Diagnóstico', style: theme.textTheme.labelLarge),
            Text(
              '${consultation.diagnosisCode ?? ''} ${consultation.diagnosisDescription ?? ''}',
            ),
            const SizedBox(height: 12),
            Text('Motivo', style: theme.textTheme.labelLarge),
            Text(consultation.reason ?? ''),
            if (consultation.clinicalNotes != null) ...[
              const SizedBox(height: 12),
              Text('Notas clínicas', style: theme.textTheme.labelLarge),
              Text(consultation.clinicalNotes!),
            ],
          ],
        ),
      ),
    );
  }
}

/// La historia previa se carga solo cuando el médico la pide:
/// cada acceso queda registrado en la auditoría.
class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.provider});

  final DoctorProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = provider.history;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Historia clínica previa', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'El acceso a la historia queda registrado en la auditoría.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        if (history == null)
          OutlinedButton.icon(
            onPressed: provider.isLoadingHistory ? null : provider.loadHistory,
            icon: const Icon(Icons.history_rounded),
            label: const Text('Ver historia previa'),
          )
        else if (history.isEmpty)
          const Text('Es la primera consulta registrada de este paciente.')
        else
          for (final record in history) MedicalRecordTile(record: record),
      ],
    );
  }
}
