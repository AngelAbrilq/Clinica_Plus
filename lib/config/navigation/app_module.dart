import 'package:material_ui/material_ui.dart';

import '../../models/user_role.dart';

enum ModuleStatus { available, comingSoon }

/// Un módulo funcional de la app (ej. "Mis citas", "Personal").
/// Los dashboards y la navegación se construyen a partir de estos datos,
/// así que agregar un módulo no exige modificar pantallas existentes.
@immutable
class AppModule {
  const AppModule({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.roles,
    this.route,
    this.status = ModuleStatus.available,
    this.navigationLabel,
    this.selectedIcon,
  });

  /// Identificador estable (útil para analítica y tests).
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final IconData? selectedIcon;
  final Set<UserRole> roles;

  /// Ruta de go_router. Obligatoria si el módulo está disponible.
  final String? route;
  final ModuleStatus status;

  /// Si no es null, el módulo aparece en la barra/menú de navegación
  /// con este texto corto (máx. ~12 caracteres).
  final String? navigationLabel;

  bool get isAvailable => status == ModuleStatus.available && route != null;
  bool get isInNavigation => isAvailable && navigationLabel != null;
}
