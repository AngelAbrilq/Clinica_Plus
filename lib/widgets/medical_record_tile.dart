import 'package:material_ui/material_ui.dart';

import '../models/medical_record.dart';
import '../utils/date_formatters.dart';

/// Registro clínico expandible (usado por médico y paciente).
class MedicalRecordTile extends StatelessWidget {
  const MedicalRecordTile({super.key, required this.record});

  final MedicalRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        title: Text(
          record.diagnosisLabel.isEmpty ? record.reason : record.diagnosisLabel,
        ),
        subtitle: Text(
          '${DateFormatters.longDate(record.consultedAt)}\n'
          '${record.specialtyName} con ${record.doctorName}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Motivo', style: theme.textTheme.labelLarge),
          Text(record.reason),
          if (record.clinicalNotes != null) ...[
            const SizedBox(height: 10),
            Text('Notas clínicas', style: theme.textTheme.labelLarge),
            Text(record.clinicalNotes!),
          ],
        ],
      ),
    );
  }
}
