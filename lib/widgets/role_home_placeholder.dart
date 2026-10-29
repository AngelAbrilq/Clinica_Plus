import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Home temporal por rol: saludo, módulos próximos y cierre de sesión.
/// Cada módulo real reemplazará su tarjeta.
class RoleHomePlaceholder extends StatelessWidget {
  const RoleHomePlaceholder({
    super.key,
    required this.title,
    required this.icon,
    required this.upcomingModules,
  });

  final String title;
  final IconData icon;
  final List<String> upcomingModules;

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
            onPressed: auth.isBusy ? null : () => context.read<AuthProvider>().signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(radius: 28, child: Icon(icon, size: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${profile?.firstName ?? ''}',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      profile?.email ?? '',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Próximamente', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final module in upcomingModules)
            Card(
              child: ListTile(
                leading: const Icon(Icons.construction_rounded),
                title: Text(module),
              ),
            ),
        ],
      ),
    );
  }
}
