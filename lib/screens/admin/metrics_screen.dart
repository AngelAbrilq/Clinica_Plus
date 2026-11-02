import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../config/theme/app_theme.dart';
import '../../models/clinic_metrics.dart';
import '../../providers/metrics_provider.dart';
import '../../utils/date_formatters.dart';
import '../../widgets/error_banner.dart';

final NumberFormat _percent = NumberFormat.percentPattern('es');

/// Indicadores de la clínica: ocupación, inasistencias, cancelaciones,
/// citas por día y por especialidad.
class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<MetricsProvider>().initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetricsProvider>();
    final theme = Theme.of(context);
    final metrics = provider.metrics;

    return Scaffold(
      appBar: AppBar(title: const Text('Indicadores')),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            SegmentedButton<MetricsPeriod>(
              segments: [
                for (final period in MetricsPeriod.values)
                  ButtonSegment(value: period, label: Text(period.label)),
              ],
              selected: {provider.period},
              onSelectionChanged: (selection) => provider.selectPeriod(selection.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${DateFormatters.longDate(provider.from)} a '
                    '${DateFormatters.longDate(provider.to).toLowerCase()}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (provider.sites.length > 1)
                  DropdownButton<int?>(
                    value: provider.siteId,
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas las sedes')),
                      for (final site in provider.sites)
                        DropdownMenuItem(value: site.id, child: Text(site.name)),
                    ],
                    onChanged: provider.selectSite,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.errorMessage != null) ErrorBanner(message: provider.errorMessage!),
            if (metrics == null)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              AnimatedOpacity(
                opacity: provider.isLoading ? 0.5 : 1,
                duration: const Duration(milliseconds: 200),
                child: _MetricsBody(metrics: metrics),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricsBody extends StatelessWidget {
  const _MetricsBody({required this.metrics});

  final ClinicMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OccupancyCard(metrics: metrics),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 600 ? 4 : 2;
            final tileWidth = (constraints.maxWidth - 10 * (columns - 1)) / columns;
            final tiles = [
              _KpiTile(label: 'Citas', value: '${metrics.total}', detail: '${metrics.pending} por atender'),
              _KpiTile(label: 'Atendidas', value: '${metrics.completed}'),
              _KpiTile(
                label: 'Inasistencia',
                value: _percent.format(metrics.noShowRate),
                detail: '${metrics.noShow} pacientes no llegaron',
                isWarning: metrics.noShowRate >= 0.15,
              ),
              _KpiTile(
                label: 'Cancelación',
                value: _percent.format(metrics.cancellationRate),
                detail: '${metrics.cancelled} canceladas',
              ),
            ];
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final tile in tiles) SizedBox(width: tileWidth, child: tile)],
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Citas por día', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Sin contar canceladas',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        _DailyBars(days: metrics.byDay, maxValue: metrics.busiestDayTotal),
        const SizedBox(height: 24),
        Text('Por especialidad', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        if (metrics.bySpecialty.isEmpty)
          const Text('Sin citas en este periodo.')
        else
          for (final specialty in metrics.bySpecialty)
            _SpecialtyBar(
              metric: specialty,
              maxTotal: metrics.bySpecialty.first.total,
            ),
      ],
    );
  }
}

/// Elemento protagonista: anillo de ocupación de la agenda.
class _OccupancyCard extends StatelessWidget {
  const _OccupancyCard({required this.metrics});

  final ClinicMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rate = metrics.occupancyRate.clamp(0.0, 1.0);
    final hours = (metrics.capacityMinutes / 60).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 108,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: rate),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, value, _) => Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      backgroundColor: colors.primaryContainer,
                      semanticsLabel: 'Ocupación de la agenda',
                      semanticsValue: _percent.format(rate),
                    ),
                    Center(
                      child: Text(
                        _percent.format(value),
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ocupación de la agenda', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    hours == 0
                        ? 'No hay horarios de médicos en este periodo.'
                        : 'De $hours horas de atención publicadas, '
                            '${(metrics.bookedMinutes / 60).round()} tienen cita.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
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

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    this.detail,
    this.isWarning = false,
  });

  final String label;
  final String value;
  final String? detail;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: isWarning ? colors.error : colors.onSurface),
            ),
            if (detail != null)
              Text(
                detail!,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

/// Barras verticales por día. Toca/mantén una barra para ver el detalle.
class _DailyBars extends StatelessWidget {
  const _DailyBars({required this.days, required this.maxValue});

  static const double _height = 120;

  final List<DailyCount> days;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (days.isEmpty) return const SizedBox(height: _height);
    final gap = days.length > 31 ? 1.0 : 3.0;
    return Semantics(
      label: 'Gráfico de citas por día. Máximo: $maxValue citas en un día.',
      child: SizedBox(
        height: _height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final day in days)
              Expanded(
                child: Tooltip(
                  message: '${DateFormatters.longDate(day.date)}: ${day.total} citas',
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: gap / 2),
                    child: Container(
                      height: maxValue == 0 ? 2 : 2 + (_height - 2) * day.total / maxValue,
                      decoration: BoxDecoration(
                        color: day.total == 0 ? colors.outlineVariant : colors.primary,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SpecialtyBar extends StatelessWidget {
  const _SpecialtyBar({required this.metric, required this.maxTotal});

  final SpecialtyMetric metric;
  final int maxTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(metric.name, style: theme.textTheme.bodyLarge)),
              Text('${metric.total}', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: LinearProgressIndicator(
              value: maxTotal == 0 ? 0 : metric.total / maxTotal,
              minHeight: 10,
              backgroundColor: colors.primaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${metric.completed} atendidas, ${metric.noShow} inasistencias, '
            '${metric.cancelled} canceladas',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
