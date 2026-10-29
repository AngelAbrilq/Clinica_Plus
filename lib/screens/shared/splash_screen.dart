import 'package:material_ui/material_ui.dart';

import '../../config/constants/app_constants.dart';

/// Se muestra mientras se restaura la sesión y se carga el perfil.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_hospital_rounded, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(AppConstants.appName, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            const CircularProgressIndicator(semanticsLabel: 'Cargando'),
          ],
        ),
      ),
    );
  }
}
