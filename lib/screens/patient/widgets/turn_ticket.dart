import 'package:material_ui/material_ui.dart';

import '../../../config/theme/app_theme.dart';
import '../../../models/patient_appointment.dart';
import '../../../utils/date_formatters.dart';
import '../../../utils/specialty_icons.dart';

/// El "turno": la próxima cita mostrada como un ticket con perforación.
/// Es el elemento visual principal del home del paciente.
class TurnTicket extends StatelessWidget {
  const TurnTicket({super.key, required this.appointment, required this.onTap});

  static const double _stubHeight = 60;

  final PatientAppointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final startsAt = appointment.startsAt!;
    final onTicket = colors.onPrimary;
    final muted = onTicket.withValues(alpha: 0.78);

    return Semantics(
      button: true,
      label:
          'Próximo turno: ${appointment.specialtyName}, '
          '${DateFormatters.longDate(startsAt)} a las ${DateFormatters.time(startsAt)}. '
          'Toca para ver el código de check-in.',
      child: ClipPath(
        clipper: const _TicketClipper(stubHeight: _stubHeight),
        child: Material(
          color: colors.primary,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tu próximo turno',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: muted,
                              ),
                            ),
                          ),
                          Icon(
                            SpecialtyIcons.forName(appointment.specialtyName),
                            color: muted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        DateFormatters.time(startsAt),
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: onTicket,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        DateFormatters.longDate(startsAt),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: onTicket,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        appointment.specialtyName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: onTicket,
                        ),
                      ),
                      Text(
                        '${appointment.doctorName}, ${appointment.siteName}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: _PerforationPainter(
                    color: onTicket.withValues(alpha: 0.45),
                  ),
                ),
                SizedBox(
                  height: _stubHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_2_rounded, color: onTicket),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mostrar código de check-in',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: onTicket,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: onTicket),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Estado vacío del ticket: invita a agendar.
class EmptyTurnTicket extends StatelessWidget {
  const EmptyTurnTicket({super.key, required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.event_available_rounded,
            color: colors.onPrimaryContainer,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'No tienes turnos pendientes',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Elige especialidad, sede y hora. Te asignamos el médico disponible.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onBook,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agendar una cita'),
          ),
        ],
      ),
    );
  }
}

/// Bordes redondeados + dos muescas semicirculares a la altura de la
/// perforación (como un ticket físico de turno).
class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper({required this.stubHeight});

  final double stubHeight;
  static const double _notchRadius = 12;

  @override
  Path getClip(Size size) {
    final notchY = size.height - stubHeight;
    final ticket = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppTheme.radiusLarge),
        ),
      );
    final notches = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(0, notchY), radius: _notchRadius),
      )
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width, notchY),
          radius: _notchRadius,
        ),
      );
    return Path.combine(PathOperation.difference, ticket, notches);
  }

  @override
  bool shouldReclip(_TicketClipper oldClipper) =>
      oldClipper.stubHeight != stubHeight;
}

/// Línea punteada de la perforación.
class _PerforationPainter extends CustomPainter {
  const _PerforationPainter({required this.color});

  final Color color;
  static const double _dash = 6;
  static const double _gap = 5;
  static const double _inset = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var x = _inset; x < size.width - _inset; x += _dash + _gap) {
      canvas.drawLine(Offset(x, 0), Offset(x + _dash, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter oldDelegate) =>
      oldDelegate.color != color;
}
