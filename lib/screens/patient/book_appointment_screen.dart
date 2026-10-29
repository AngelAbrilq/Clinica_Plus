import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../config/constants/app_constants.dart';
import '../../config/routes/app_routes.dart';
import '../../models/available_slot.dart';
import '../../models/site.dart';
import '../../models/specialty.dart';
import '../../providers/appointment_provider.dart';
import '../../utils/date_formatters.dart';
import '../../utils/specialty_icons.dart';
import '../../widgets/animations/fade_slide_in.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_button.dart';

/// Agendamiento en una sola pantalla que se va revelando por pasos:
/// especialidad → sede → fecha → hora → síntomas → confirmar.
class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  static const int _daysAhead = 14;

  final _symptomsController = TextEditingController();
  late final List<DateTime> _dates = List.generate(_daysAhead, (offset) {
    final today = DateUtils.dateOnly(DateTime.now());
    return today.add(Duration(days: offset));
  });

  Specialty? _specialty;
  Site? _site;
  DateTime? _date;
  AvailableSlot? _slot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AppointmentProvider>()..clearSlots();
      await provider.loadCatalogs();
      // Con una sola sede, se preselecciona.
      if (mounted && provider.sites.length == 1) setState(() => _site = provider.sites.first);
    });
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  void _reloadSlots() {
    final provider = context.read<AppointmentProvider>();
    setState(() => _slot = null);
    final specialty = _specialty;
    final site = _site;
    final date = _date;
    if (specialty == null || site == null || date == null) {
      provider.clearSlots();
      return;
    }
    provider.loadSlots(specialtyId: specialty.id, siteId: site.id, date: date);
  }

  Future<void> _confirm() async {
    final specialty = _specialty!;
    final site = _site!;
    final slot = _slot!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(SpecialtyIcons.forName(specialty.name)),
        title: const Text('Confirmar cita'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryRow(icon: Icons.local_hospital_outlined, text: specialty.name),
            _SummaryRow(icon: Icons.place_outlined, text: site.name),
            _SummaryRow(
              icon: Icons.event_outlined,
              text: DateFormatters.longDate(slot.startsAt),
            ),
            _SummaryRow(
              icon: Icons.schedule_rounded,
              text: DateFormatters.timeRange(slot.startsAt, slot.endsAt),
            ),
            const SizedBox(height: 8),
            Text(
              'Te asignaremos el médico disponible. Llega 10 minutos antes.',
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cambiar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Agendar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<AppointmentProvider>();
    final appointmentId = await provider.book(
      specialtyId: specialty.id,
      siteId: site.id,
      slot: slot,
      symptoms: _symptomsController.text,
    );
    if (!mounted) return;
    if (appointmentId == null) {
      // Probablemente alguien tomó ese horario: se recargan las horas.
      _reloadSlots();
      return;
    }
    context.pushReplacement(AppRoutes.patientAppointmentDetailPath(appointmentId, isNew: true));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Agendar cita')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _slot == null
                ? Text(
                    'Elige especialidad, sede, fecha y hora',
                    key: const ValueKey('hint'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  )
                : LoadingButton(
                    key: const ValueKey('confirm'),
                    label: 'Confirmar · ${DateFormatters.time(_slot!.startsAt)}',
                    isLoading: provider.isSaving,
                    onPressed: _confirm,
                  ),
          ),
        ),
      ),
      body: provider.isLoadingCatalogs && provider.specialties.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const _EmergencyNotice(),
                if (provider.errorMessage != null)
                  ErrorBanner(message: provider.errorMessage!, onDismiss: provider.clearError),
                const _SectionTitle(number: 1, title: '¿Qué especialidad necesitas?'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final specialty in provider.specialties)
                      ChoiceChip(
                        avatar: Icon(SpecialtyIcons.forName(specialty.name), size: 18),
                        label: Text(specialty.name),
                        selected: _specialty?.id == specialty.id,
                        onSelected: (_) {
                          setState(() => _specialty = specialty);
                          _reloadSlots();
                        },
                      ),
                  ],
                ),
                if (_specialty != null) ...[
                  const _SectionTitle(number: 2, title: 'Sede'),
                  FadeSlideIn(
                    child: SegmentedButton<int>(
                      emptySelectionAllowed: true,
                      segments: [
                        for (final site in provider.sites)
                          ButtonSegment(
                            value: site.id,
                            label: Text(site.name),
                            icon: const Icon(Icons.place_outlined),
                          ),
                      ],
                      selected: {if (_site != null) _site!.id},
                      onSelectionChanged: (selection) {
                        if (selection.isEmpty) return;
                        setState(() {
                          _site = provider.sites.firstWhere((site) => site.id == selection.first);
                        });
                        _reloadSlots();
                      },
                    ),
                  ),
                ],
                if (_specialty != null && _site != null) ...[
                  const _SectionTitle(number: 3, title: 'Fecha'),
                  FadeSlideIn(
                    child: SizedBox(
                      height: 86,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _dates.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, index) => _DateCard(
                          date: _dates[index],
                          isToday: index == 0,
                          isSelected: _date == _dates[index],
                          onTap: () {
                            setState(() => _date = _dates[index]);
                            _reloadSlots();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
                if (_date != null) ...[
                  const _SectionTitle(number: 4, title: 'Hora'),
                  _SlotsSection(
                    isLoading: provider.isLoadingSlots,
                    slots: provider.slots,
                    selected: _slot,
                    onSelected: (slot) => setState(() => _slot = slot),
                  ),
                ],
                if (_slot != null) ...[
                  const _SectionTitle(number: 5, title: '¿Qué sientes? (opcional)'),
                  FadeSlideIn(
                    child: TextField(
                      controller: _symptomsController,
                      maxLength: 500,
                      minLines: 2,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Ej: fiebre y dolor de garganta desde hace 2 días',
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _EmergencyNotice extends StatelessWidget {
  const _EmergencyNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.error),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.emergency_outlined, color: colors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '¿Es una emergencia? Si tienes dolor en el pecho, dificultad para '
              'respirar o sangrado abundante, llama al ${AppConstants.emergencyPhone} '
              'o ve a urgencias.',
              style: TextStyle(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.number, required this.title});

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              '$number',
              style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Text(title, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isSelected ? colors.onPrimary : colors.onSurface;
    return Semantics(
      selected: isSelected,
      button: true,
      label: DateFormatters.longDate(date),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 62,
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isToday ? 'Hoy' : DateFormatters.weekdayShort(date),
                style: TextStyle(color: foreground, fontSize: 12),
              ),
              Text(
                '${date.day}',
                style: TextStyle(color: foreground, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              Text(
                DateFormatters.monthShort(date),
                style: TextStyle(color: foreground, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotsSection extends StatelessWidget {
  const _SlotsSection({
    required this.isLoading,
    required this.slots,
    required this.selected,
    required this.onSelected,
  });

  final bool isLoading;
  final List<AvailableSlot> slots;
  final AvailableSlot? selected;
  final ValueChanged<AvailableSlot> onSelected;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (slots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No hay horarios disponibles este día. Prueba con otra fecha.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }
    final morning = slots.where((slot) => slot.isMorning).toList();
    final afternoon = slots.where((slot) => !slot.isMorning).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (morning.isNotEmpty) _buildGroup(context, 'Mañana', Icons.wb_sunny_outlined, morning),
        if (afternoon.isNotEmpty)
          _buildGroup(context, 'Tarde', Icons.wb_twilight_outlined, afternoon),
      ],
    );
  }

  Widget _buildGroup(
    BuildContext context,
    String label,
    IconData icon,
    List<AvailableSlot> group,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 6),
                Text(label, style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (index, slot) in group.indexed)
                  FadeSlideIn(
                    key: ValueKey(slot.startsAt),
                    delay: FadeSlideIn.staggerDelay(index, stepMs: 30, maxSteps: 12),
                    child: ChoiceChip(
                      label: Text(DateFormatters.time(slot.startsAt)),
                      selected: selected?.startsAt == slot.startsAt,
                      onSelected: (_) => onSelected(slot),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
