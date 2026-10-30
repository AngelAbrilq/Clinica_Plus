import 'package:material_ui/material_ui.dart';

import '../utils/date_formatters.dart';

/// Navegación por días: ‹ Hoy / lunes 2 de noviembre › + "Volver a hoy".
/// Compartido por la agenda de recepción y la del médico.
class DateNavigator extends StatelessWidget {
  const DateNavigator({
    super.key,
    required this.date,
    required this.isToday,
    required this.onShift,
    required this.onToday,
  });

  final DateTime date;
  final bool isToday;
  final ValueChanged<int> onShift;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Día anterior',
              onPressed: () => onShift(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    isToday ? 'Hoy' : DateFormatters.weekdayShort(date),
                    style: theme.textTheme.labelLarge,
                  ),
                  Text(
                    DateFormatters.longDate(date),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Día siguiente',
              onPressed: () => onShift(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        if (!isToday)
          TextButton(onPressed: onToday, child: const Text('Volver a hoy')),
      ],
    );
  }
}
