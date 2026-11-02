import 'package:material_ui/material_ui.dart';

import '../../../models/reception_appointment.dart';
import '../../../utils/date_formatters.dart';

/// Resultado del check-in: éxito (con datos del paciente) o error claro.
/// Devuelve cuando recepción toca "Escanear otro" / "Entendido".
Future<void> showCheckInResultSheet(
  BuildContext context, {
  CheckInResult? result,
  String? errorMessage,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (_) =>
      _CheckInResultSheet(result: result, errorMessage: errorMessage),
);

class _CheckInResultSheet extends StatelessWidget {
  const _CheckInResultSheet({this.result, this.errorMessage});

  final CheckInResult? result;
  final String? errorMessage;

  String _arrivalText(int minutes) => switch (minutes) {
    > 0 => 'Llegó $minutes min antes de su hora',
    0 => 'Llegó justo a tiempo',
    _ => 'Llegó ${-minutes} min tarde (dentro de la tolerancia)',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final success = result;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: success != null
                    ? colors.tertiaryContainer
                    : colors.errorContainer,
                child: Icon(
                  success != null
                      ? Icons.how_to_reg_rounded
                      : Icons.error_outline_rounded,
                  size: 38,
                  color: success != null
                      ? colors.onTertiaryContainer
                      : colors.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (success != null) ...[
              Text(
                success.patientName,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Check-in registrado. Puede pasar a la sala de espera.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        success.specialtyName,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '${success.doctorName}, ${DateFormatters.time(success.startsAt)}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _arrivalText(success.minutesUntilStart),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Text(
                'No se pudo hacer el check-in',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ?? '',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(success != null ? 'Escanear otro' : 'Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
