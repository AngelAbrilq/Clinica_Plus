import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../config/navigation/app_module.dart';
import '../../config/navigation/app_modules.dart';
import '../../config/theme/app_theme.dart';
import '../../models/user_role.dart';
import '../../providers/auth_provider.dart';
import '../animations/fade_slide_in.dart';

/// Dashboard genérico para cualquier rol:
///   saludo → [hero] opcional → módulos disponibles → próximamente → [footer].
/// Los módulos salen de [AppModules]; esta pantalla no se modifica
/// cuando se agregan módulos nuevos.
class RoleDashboard extends StatelessWidget {
  const RoleDashboard({
    super.key,
    required this.role,
    this.hero,
    this.footer,
    this.onRefresh,
    this.subtitle,
  });

  final UserRole role;

  /// Bloque destacado propio del rol (ej. el ticket del próximo turno).
  final Widget? hero;
  final Widget? footer;
  final Future<void> Function()? onRefresh;
  final String? subtitle;

  static String greetingFor(DateTime now) => switch (now.hour) {
    < 12 => 'Buenos días',
    < 19 => 'Buenas tardes',
    _ => 'Buenas noches',
  };

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final available = AppModules.availableFor(role);
    final comingSoon = AppModules.comingSoonFor(role);

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          '${greetingFor(DateTime.now())}, ${auth.profile?.firstName ?? ''}',
          style: theme.textTheme.headlineMedium,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 22),
        if (hero != null) ...[hero!, const SizedBox(height: 28)],
        if (available.isNotEmpty) _ModuleGrid(modules: available),
        if (comingSoon.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text('En camino', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final module in comingSoon)
                Tooltip(
                  message: module.description,
                  child: Chip(
                    avatar: Icon(
                      module.icon,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                    label: Text(module.title),
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (footer != null) ...[const SizedBox(height: 24), footer!],
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(AppModules.dashboardTitle(role)),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: auth.isBusy
                ? null
                : () => context.read<AuthProvider>().signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: onRefresh == null
          ? content
          : RefreshIndicator(onRefresh: onRefresh!, child: content),
    );
  }
}

/// Cuadrícula responsive: 1 columna en celular, 2 en tablet, 3 en escritorio.
class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({required this.modules});

  final List<AppModule> modules;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 3
          : constraints.maxWidth >= 560
          ? 2
          : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: modules.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 92,
        ),
        itemBuilder: (_, index) => FadeSlideIn(
          delay: FadeSlideIn.staggerDelay(index, stepMs: 70),
          child: _ModuleTile(module: modules[index]),
        ),
      );
    },
  );
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.module});

  final AppModule module;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Los módulos de la barra de navegación se abren como pestaña (go);
        // el resto se apila encima del dashboard (push) para volver atrás.
        onTap: () => module.isInNavigation
            ? context.go(module.route!)
            : context.push(module.route!),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(module.icon, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.title, style: theme.textTheme.titleMedium),
                    Text(
                      module.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
