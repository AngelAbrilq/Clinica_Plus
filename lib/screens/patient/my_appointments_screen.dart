import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../config/routes/app_routes.dart';
import '../../models/patient_appointment.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/animations/fade_slide_in.dart';
import '../../widgets/error_banner.dart';
import 'widgets/appointment_card.dart';

/// Citas del paciente: próximas e historial.
class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AppointmentProvider>().loadMyAppointments(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis citas'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Próximas (${provider.upcoming.length})'),
              const Tab(text: 'Historial'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.patientBook),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Agendar'),
        ),
        body: Column(
          children: [
            if (provider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ErrorBanner(
                  message: provider.errorMessage!,
                  onDismiss: provider.clearError,
                ),
              ),
            Expanded(
              child:
                  provider.isLoadingAppointments &&
                      provider.appointments.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _AppointmentList(
                          appointments: provider.upcoming,
                          emptyMessage: 'No tienes citas próximas.\nToca "Agendar" para pedir una.',
                          onRefresh: provider.loadMyAppointments,
                        ),
                        _AppointmentList(
                          appointments: provider.history,
                          emptyMessage: 'Aún no tienes historial de citas.',
                          onRefresh: provider.loadMyAppointments,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList({
    required this.appointments,
    required this.emptyMessage,
    required this.onRefresh,
  });

  final List<PatientAppointment> appointments;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: appointments.isEmpty
        ? ListView(
            padding: const EdgeInsets.all(40),
            children: [
              Icon(
                Icons.event_available_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(emptyMessage, textAlign: TextAlign.center),
            ],
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: appointments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, index) => FadeSlideIn(
              key: ValueKey(appointments[index].id),
              delay: FadeSlideIn.staggerDelay(index),
              child: AppointmentCard(
                appointment: appointments[index],
                onTap: () => context.push(
                  AppRoutes.patientAppointmentDetailPath(
                    appointments[index].id,
                  ),
                ),
              ),
            ),
          ),
  );
}
