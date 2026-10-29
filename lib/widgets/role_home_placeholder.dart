import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'animations/fade_slide_in.dart';

/// Acceso a un módulo ya disponible desde el home del rol.
class HomeAction {
  const HomeAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

/// Home por rol: saludo, módulos disponibles, módulos próximos y logout.
class RoleHomePlaceholder extends StatelessWidget {
  const RoleHomePlaceholder({
    super.key,
    required this.title,
    required this.icon,
    required this.upcomingModules,
    this.actions = const [],
  });

  final String title;
  final IconData icon;
  final List<String> upcomingModules;
  final List<HomeAction> actions;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final profile = auth.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FadeSlideIn(
            child: Row(
              children: [
                CircleAvatar(radius: 28, child: Icon(icon, size: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${profile?.firstName ?? ''}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        profile?.email ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('Módulos', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final (index, action) in actions.indexed)
              FadeSlideIn(
                delay: FadeSlideIn.staggerDelay(index + 1, stepMs: 80),
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      action.icon,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(action.title),
                    subtitle: Text(action.subtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(action.route),
                  ),
                ),
              ),
          ],
          if (upcomingModules.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('Próximamente', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final (index, module) in upcomingModules.indexed)
              FadeSlideIn(
                delay: FadeSlideIn.staggerDelay(
                  index + actions.length + 1,
                  stepMs: 80,
                ),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.construction_rounded),
                    title: Text(module),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
