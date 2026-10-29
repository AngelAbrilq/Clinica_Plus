import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/constants/app_constants.dart';
import 'config/env.dart';
import 'config/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.validate();
  await initializeDateFormatting('es_CO');
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  runApp(const ClinicaPlusApp());
}

class ClinicaPlusApp extends StatelessWidget {
  const ClinicaPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider + go_router se agregan en el módulo de Auth.
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: const _BootstrapScreen(),
    );
  }
}

/// Pantalla temporal para validar tema y conexión con Supabase.
class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_hospital_rounded,
                size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(AppConstants.appName, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Supabase conectado ✔'),
          ],
        ),
      ),
    );
  }
}
