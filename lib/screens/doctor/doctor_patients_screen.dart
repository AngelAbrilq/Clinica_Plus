import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../config/routes/app_routes.dart';
import '../../models/doctor_patient.dart';
import '../../providers/doctor_patients_provider.dart';
import '../../utils/date_formatters.dart';
import '../../widgets/error_banner.dart';

/// Pacientes del médico con buscador por nombre o documento.
class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  late final TextEditingController _search =
      TextEditingController(text: context.read<DoctorPatientsProvider>().query);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DoctorPatientsProvider>().search(),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clear() {
    _search.clear();
    context.read<DoctorPatientsProvider>()
      ..onQueryChanged('')
      ..search();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorPatientsProvider>();
    final theme = Theme.of(context);
    final patients = provider.patients;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis pacientes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: provider.onQueryChanged,
              onSubmitted: (_) => provider.search(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o documento',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: _clear,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          if (provider.isLoading) const LinearProgressIndicator(minHeight: 2),
          if (provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ErrorBanner(message: provider.errorMessage!),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.search,
              child: patients.isEmpty && !provider.isLoading
                  ? ListView(
                      padding: const EdgeInsets.all(40),
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 56, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          provider.query.trim().isEmpty
                              ? 'Aún no tienes pacientes. Aparecerán cuando te asignen citas.'
                              : 'Ningún paciente coincide con "${provider.query.trim()}".',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: patients.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) => _PatientTile(
                        patient: patients[index],
                        onTap: () => context.push(
                          AppRoutes.doctorPatientChartPath(patients[index].id),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  const _PatientTile({required this.patient, required this.onTap});

  final DoctorPatient patient;
  final VoidCallback onTap;

  String get _visitsText {
    final last = patient.lastVisitAt;
    if (last == null) return 'Aún sin consultas atendidas';
    final count = patient.completedVisits;
    return '${count == 1 ? '1 consulta' : '$count consultas'}, '
        'la última el ${DateFormatters.longDate(last).toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final details = [
      if (patient.document != null) patient.document!,
      if (patient.age != null) '${patient.age} años',
    ].join(', ');
    final next = patient.nextVisitAt;

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          child: Text(patient.initial, style: TextStyle(color: colors.onPrimaryContainer)),
        ),
        title: Text(patient.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details.isNotEmpty) Text(details),
            Text(_visitsText, style: theme.textTheme.bodySmall),
            if (next != null)
              Text(
                'Próxima cita: ${DateFormatters.longDate(next).toLowerCase()}, '
                '${DateFormatters.time(next)}',
                style: theme.textTheme.bodySmall?.copyWith(color: colors.primary),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
