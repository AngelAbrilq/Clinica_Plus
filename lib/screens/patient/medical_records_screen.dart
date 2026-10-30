import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/doctor_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/medical_record_tile.dart';

/// Historia clínica del paciente (diagnósticos y notas de sus consultas).
class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<MedicalRecordsProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicalRecordsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mi historia clínica')),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (provider.errorMessage != null)
              ErrorBanner(message: provider.errorMessage!),
            if (provider.isLoading && provider.records.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.records.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Aquí verás el diagnóstico y las notas de cada consulta '
                  'cuando el médico la finalice.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final record in provider.records)
                MedicalRecordTile(record: record),
          ],
        ),
      ),
    );
  }
}
