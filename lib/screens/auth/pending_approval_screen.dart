import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/auth_scaffold.dart';

/// Personal con correo de la clínica cuya cuenta aún no tiene rol asignado.
class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AuthScaffold(
      title: 'Cuenta pendiente de aprobación',
      subtitle: 'El administrador debe asignarte un rol (médico o recepción) '
          'antes de que puedas usar la aplicación.',
      child: OutlinedButton.icon(
        onPressed: auth.isBusy ? null : () => context.read<AuthProvider>().signOut(),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Cerrar sesión'),
      ),
    );
  }
}
