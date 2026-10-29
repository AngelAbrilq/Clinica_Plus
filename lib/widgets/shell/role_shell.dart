import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../config/navigation/app_modules.dart';
import '../../config/routes/app_routes.dart';
import '../../models/user_role.dart';

/// Destino de navegación (Inicio + módulos marcados en el registro).
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}

/// Marco de navegación por rol:
/// · celular: barra inferior (NavigationBar)
/// · tablet/web ≥ 840 px: menú lateral (NavigationRail)
/// Solo se muestra en las pantallas raíz (Inicio, Citas, Personal…);
/// en pantallas de detalle el contenido ocupa todo el espacio.
class RoleShell extends StatelessWidget {
  const RoleShell({
    super.key,
    required this.role,
    required this.location,
    required this.child,
  });

  static const double railBreakpoint = 840;
  static const double extendedRailBreakpoint = 1200;

  final UserRole role;
  final String location;
  final Widget child;

  /// Inicio siempre primero; luego los módulos con `navigationLabel`.
  static List<ShellDestination> destinationsFor(UserRole role) => [
    ShellDestination(
      label: 'Inicio',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      route: AppRoutes.homeFor(role),
    ),
    for (final module in AppModules.navigationFor(role))
      ShellDestination(
        label: module.navigationLabel!,
        icon: module.icon,
        selectedIcon: module.selectedIcon ?? module.icon,
        route: module.route!,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final destinations = destinationsFor(role);
    final selectedIndex = destinations.indexWhere(
      (item) => item.route == location,
    );
    // Material exige al menos 2 destinos; y en detalles no se muestra.
    if (destinations.length < 2 || selectedIndex < 0) return child;

    void onSelected(int index) => context.go(destinations[index].route);
    final width = MediaQuery.sizeOf(context).width;

    if (width >= railBreakpoint) {
      final extended = width >= extendedRailBreakpoint;
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: extended,
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelected,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: [
                for (final item in destinations)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: [
          for (final item in destinations)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}
