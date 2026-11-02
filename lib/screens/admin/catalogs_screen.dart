import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/catalog_usage.dart';
import '../../models/site.dart';
import '../../models/specialty.dart';
import '../../providers/catalog_admin_provider.dart';
import '../../utils/specialty_icons.dart';
import '../../widgets/error_banner.dart';
import 'widgets/catalog_form_sheets.dart';

/// Sedes y especialidades: crear, editar y activar/desactivar.
class CatalogsScreen extends StatefulWidget {
  const CatalogsScreen({super.key});

  @override
  State<CatalogsScreen> createState() => _CatalogsScreenState();
}

class _CatalogsScreenState extends State<CatalogsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(() {
      if (!_tabs.indexIsChanging) setState(() {}); // actualiza el botón flotante
    });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<CatalogAdminProvider>().load(),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool get _isSitesTab => _tabs.index == 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CatalogAdminProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sedes y especialidades'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Sedes'), Tab(text: 'Especialidades')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isSaving
            ? null
            : () => _isSitesTab
                ? showSiteFormSheet(context)
                : showSpecialtyFormSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(_isSitesTab ? 'Nueva sede' : 'Nueva especialidad'),
      ),
      body: Column(
        children: [
          if (provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ErrorBanner(message: provider.errorMessage!, onDismiss: provider.clearError),
            ),
          Expanded(
            child: provider.isLoading && provider.sites.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _CatalogList(
                        onRefresh: provider.load,
                        children: [
                          for (final site in provider.sortedSites)
                            _SiteTile(site: site, usage: provider.overview.siteUsage(site.id)),
                        ],
                      ),
                      _CatalogList(
                        onRefresh: provider.load,
                        children: [
                          for (final specialty in provider.sortedSpecialties)
                            _SpecialtyTile(
                              specialty: specialty,
                              usage: provider.overview.specialtyUsage(specialty.id),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CatalogList extends StatelessWidget {
  const _CatalogList({required this.children, required this.onRefresh});

  final List<Widget> children;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, index) => children[index],
        ),
      );
}

/// Texto de uso: "2 médicos con horario, 3 citas próximas".
String _usageText(CatalogUsage usage, {required String doctorsLabel}) {
  String plural(int count, String singular, String pluralForm) =>
      '$count ${count == 1 ? singular : pluralForm}';
  return '${plural(usage.doctors, 'médico', 'médicos')} $doctorsLabel, '
      '${plural(usage.upcomingAppointments, 'cita próxima', 'citas próximas')}';
}

/// Confirma la desactivación explicando el efecto real.
Future<bool> _confirmDeactivation(
  BuildContext context, {
  required String name,
  required CatalogUsage usage,
  required String effect,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Desactivar $name'),
        content: Text(
          usage.upcomingAppointments > 0
              ? '$effect Las ${usage.upcomingAppointments} citas ya agendadas se mantienen; '
                  'avísale a esos pacientes si deben cambiar de sede o especialidad.'
              : effect,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    ) ??
    false;

class _SiteTile extends StatelessWidget {
  const _SiteTile({required this.site, required this.usage});

  final Site site;
  final CatalogUsage usage;

  Future<void> _toggle(BuildContext context) async {
    final provider = context.read<CatalogAdminProvider>();
    if (site.isActive) {
      final confirmed = await _confirmDeactivation(
        context,
        name: site.name,
        usage: usage,
        effect: 'Los pacientes ya no podrán agendar citas en esta sede.',
      );
      if (!confirmed) return;
    }
    await provider.setSiteActive(site, isActive: !site.isActive);
  }

  @override
  Widget build(BuildContext context) => _CatalogTile(
        icon: Icons.apartment_rounded,
        title: site.name,
        lines: [
          site.address,
          if (site.phone != null) site.phone!,
          _usageText(usage, doctorsLabel: 'con horario'),
        ],
        isActive: site.isActive,
        onEdit: () => showSiteFormSheet(context, site: site),
        onToggle: () => _toggle(context),
      );
}

class _SpecialtyTile extends StatelessWidget {
  const _SpecialtyTile({required this.specialty, required this.usage});

  final Specialty specialty;
  final CatalogUsage usage;

  Future<void> _toggle(BuildContext context) async {
    final provider = context.read<CatalogAdminProvider>();
    if (specialty.isActive) {
      final confirmed = await _confirmDeactivation(
        context,
        name: specialty.name,
        usage: usage,
        effect: 'Dejará de aparecer al agendar citas.',
      );
      if (!confirmed) return;
    }
    await provider.setSpecialtyActive(specialty, isActive: !specialty.isActive);
  }

  @override
  Widget build(BuildContext context) => _CatalogTile(
        icon: SpecialtyIcons.forName(specialty.name),
        title: specialty.name,
        lines: [
          'Consultas de ${specialty.slotMinutes} minutos',
          if (specialty.description != null) specialty.description!,
          _usageText(usage, doctorsLabel: 'activos'),
        ],
        isActive: specialty.isActive,
        onEdit: () => showSpecialtyFormSheet(context, specialty: specialty),
        onToggle: () => _toggle(context),
      );
}

enum _TileAction { edit, toggle }

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({
    required this.icon,
    required this.title,
    required this.lines,
    required this.isActive,
    required this.onEdit,
    required this.onToggle,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Opacity(
      opacity: isActive ? 1 : 0.6,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: isActive ? colors.primary : colors.onSurfaceVariant),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(title, style: theme.textTheme.titleMedium)),
                        if (!isActive) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Inactiva',
                            style: theme.textTheme.labelMedium?.copyWith(color: colors.error),
                          ),
                        ],
                      ],
                    ),
                    for (final line in lines)
                      Text(
                        line,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<_TileAction>(
                tooltip: 'Opciones',
                onSelected: (action) {
                  switch (action) {
                    case _TileAction.edit:
                      onEdit();
                    case _TileAction.toggle:
                      onToggle();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: _TileAction.edit, child: Text('Editar')),
                  PopupMenuItem(
                    value: _TileAction.toggle,
                    child: Text(isActive ? 'Desactivar' : 'Activar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
