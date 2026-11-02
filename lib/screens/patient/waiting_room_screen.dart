import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../config/constants/app_constants.dart';
import '../../config/routes/app_routes.dart';
import '../../config/theme/app_theme.dart';
import '../../models/appointment_status.dart';
import '../../models/queue_status.dart';
import '../../providers/waiting_room_provider.dart';
import '../../utils/date_formatters.dart';
import '../../widgets/error_banner.dart';

/// Sala de espera en vivo: cuántas personas faltan y hora estimada.
class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key, required this.appointmentId});

  final int appointmentId;

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  /// Referencia guardada: en dispose() no se debe usar context.read.
  late final WaitingRoomProvider _provider = context.read<WaitingRoomProvider>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider
        ..addListener(_onProviderChanged)
        ..start(widget.appointmentId);
    });
  }

  void _onProviderChanged() {
    if (_provider.consumeTurnArrived()) HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _provider
      ..removeListener(_onProviderChanged)
      ..stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WaitingRoomProvider>();
    final theme = Theme.of(context);
    final status = provider.status;
    final updated = provider.lastUpdated;

    return Scaffold(
      appBar: AppBar(title: const Text('Sala de espera')),
      body: RefreshIndicator(
        onRefresh: provider.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (provider.errorMessage != null) ErrorBanner(message: provider.errorMessage!),
            if (status == null)
              const Padding(
                padding: EdgeInsets.all(64),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: KeyedSubtree(
                  key: ValueKey(status.status),
                  child: _QueueHero(status: status, now: provider.now),
                ),
              ),
              const SizedBox(height: 20),
              _AppointmentSummary(status: status),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.sensors_rounded, size: 16, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      updated == null
                          ? 'Se actualiza en vivo'
                          : 'Se actualiza en vivo. Última actualización: '
                              '${DateFormatters.time(updated)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QueueHero extends StatelessWidget {
  const _QueueHero({required this.status, required this.now});

  final QueueStatus status;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (status.isYourTurn) return const _YourTurnCard();
    if (status.isOver) return _FinishedCard(status: status);

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ahead = status.peopleAhead;
    final minutes = status.minutesUntilEstimated(now);
    final estimated = status.estimatedStart;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status.hasNotArrived) ...[
            Row(
              children: [
                Icon(Icons.qr_code_2_rounded, color: colors.onPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aún no registras tu llegada. Muestra tu código QR en recepción.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: colors.onPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Semantics(
            liveRegion: true,
            label: ahead == 0
                ? 'Eres el siguiente'
                : '$ahead ${ahead == 1 ? 'persona' : 'personas'} antes que tú',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // El número cambia con un giro hacia arriba cuando avanza la fila.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (child, animation) => SlideTransition(
                    position: Tween(begin: const Offset(0, 0.6), end: Offset.zero)
                        .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Text(
                    '$ahead',
                    key: ValueKey(ahead),
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      ahead == 0
                          ? 'Eres el siguiente'
                          : ahead == 1
                              ? 'persona antes que tú'
                              : 'personas antes que tú',
                      style: theme.textTheme.titleMedium?.copyWith(color: colors.onPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (estimated != null) ...[
            const SizedBox(height: 16),
            Text(
              'Hora estimada de atención: ${DateFormatters.time(estimated)}',
              style: theme.textTheme.titleMedium?.copyWith(color: colors.onPrimary),
            ),
            if (minutes != null && minutes > 0)
              Text(
                'En unos $minutes minutos',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.onPrimary.withValues(alpha: 0.8)),
              ),
          ],
        ],
      ),
    );
  }
}

/// "Es tu turno": tarjeta verde que late suavemente.
class _YourTurnCard extends StatefulWidget {
  const _YourTurnCard();

  @override
  State<_YourTurnCard> createState() => _YourTurnCardState();
}

class _YourTurnCardState extends State<_YourTurnCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context) && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.03)
          .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.tertiary,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Column(
            children: [
              Icon(Icons.campaign_rounded, size: 56, color: colors.onTertiary),
              const SizedBox(height: 12),
              Text(
                '¡Es tu turno!',
                style: theme.textTheme.headlineMedium?.copyWith(color: colors.onTertiary),
              ),
              const SizedBox(height: 4),
              Text(
                'Dirígete al consultorio.',
                style: theme.textTheme.titleMedium?.copyWith(color: colors.onTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinishedCard extends StatelessWidget {
  const _FinishedCard({required this.status});

  final QueueStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = status.status == AppointmentStatus.completed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              completed ? Icons.task_alt_rounded : Icons.event_busy_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              completed ? 'Consulta finalizada' : 'Esta cita ya no está activa',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              completed
                  ? 'El diagnóstico ya está en tu historia clínica.'
                  : 'Estado: ${status.status.label}.',
              textAlign: TextAlign.center,
            ),
            if (completed) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => context.go(AppRoutes.patientRecords),
                child: const Text('Ver mi historia clínica'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppointmentSummary extends StatelessWidget {
  const _AppointmentSummary({required this.status});

  final QueueStatus status;

  @override
  Widget build(BuildContext context) => Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.local_hospital_outlined),
              title: Text(status.specialtyName),
              subtitle: Text(status.doctorName),
            ),
            ListTile(
              leading: const Icon(Icons.schedule_rounded),
              title: Text('Cita a las ${DateFormatters.time(status.startsAt)}'),
              subtitle: Text(status.siteName),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Si te retrasas'),
              subtitle: Text(
                'La tolerancia es de ${AppConstants.lateTolerance.inMinutes} minutos '
                'después de tu hora.',
              ),
            ),
          ],
        ),
      );
}
