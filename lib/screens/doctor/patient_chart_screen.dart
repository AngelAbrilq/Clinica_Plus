import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/doctor_patients_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/medical_record_tile.dart';

/// Historia clínica completa de un paciente del médico.
/// Abrirla queda registrado en la auditoría.
class PatientChartScreen extends StatefulWidget {
  const PatientChartScreen({super.key, required this.patientId});

  final String patientId;

  @override
  State<PatientChartScreen> createState() => _PatientChartScreenState();
}

class _PatientChartScreenState extends State<PatientChartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DoctorPatientsProvider>().openChart(widget.patientId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorPatientsProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final patient = provider.patientById(widget.patientId);
    final records = provider.chart;

    return Scaffold(
      appBar: AppBar(title: Text(patient?.name ?? 'Historia clínica')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (patient != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: colors.primaryContainer,
                      child: Text(
                        patient.initial,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: colors.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patient.name, style: theme.textTheme.titleMedium),
                          if (patient.document != null) Text(patient.document!),
                          if (patient.age != null) Text('${patient.age} años'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Información confidencial. Esta consulta queda registrada en la auditoría.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (provider.errorMessage != null) ErrorBanner(message: provider.errorMessage!),
          if (provider.isLoadingChart)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (records != null && records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Este paciente aún no tiene consultas registradas.',
                textAlign: TextAlign.center,
              ),
            )
          else if (records != null) ...[
            Text(
              records.length == 1 ? '1 consulta' : '${records.length} consultas',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final record in records) MedicalRecordTile(record: record),
          ],
        ],
      ),
    );
  }
}
