import 'package:clinica_plus/config/navigation/app_module.dart';
import 'package:clinica_plus/config/navigation/app_modules.dart';
import 'package:clinica_plus/config/routes/app_routes.dart';
import 'package:clinica_plus/models/user_role.dart';
import 'package:clinica_plus/widgets/shell/role_shell.dart';
import 'package:flutter_test/flutter_test.dart';

/// Estos tests protegen el registro: si alguien agrega un módulo mal
/// configurado, fallan antes de llegar a producción.
void main() {
  group('Integridad del registro', () {
    test('los ids son únicos', () {
      final ids = AppModules.all.map((module) => module.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('todo módulo disponible tiene ruta', () {
      for (final module in AppModules.all.where(
        (module) => module.status == ModuleStatus.available,
      )) {
        expect(module.route, isNotNull, reason: '${module.id} no tiene ruta');
      }
    });

    test('cada ruta de módulo pertenece a la sección de sus roles', () {
      // Si no, el guard de go_router redirigiría al usuario a su inicio.
      for (final module in AppModules.all.where(
        (module) => module.isAvailable,
      )) {
        for (final role in module.roles) {
          expect(
            AppRoutes.canAccess(module.route!, role),
            isTrue,
            reason: '${module.id} no es accesible para ${role.name}',
          );
        }
      }
    });

    test('todo módulo pertenece al menos a un rol', () {
      expect(AppModules.all.every((module) => module.roles.isNotEmpty), isTrue);
    });
  });

  group('Navegación por rol', () {
    test('paciente: Inicio + Citas', () {
      final labels = RoleShell.destinationsFor(UserRole.patient)
          .map((d) => d.label);
      expect(labels, ['Inicio', 'Citas']);
    });

    test('admin: Inicio + Personal', () {
      final routes = RoleShell.destinationsFor(UserRole.admin)
          .map((d) => d.route);
      expect(routes, [AppRoutes.adminHome, AppRoutes.adminStaff]);
    });

    test('un módulo "próximamente" nunca aparece en la navegación', () {
      for (final role in UserRole.values) {
        expect(
          AppModules.navigationFor(role).every((module) => module.isAvailable),
          isTrue,
        );
      }
    });

    test('el perfil (compartido) aparece como próximamente para todos', () {
      for (final role in UserRole.values) {
        expect(
          AppModules.comingSoonFor(role).map((module) => module.id),
          contains('shared.profile'),
        );
      }
    });
  });
}
