import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/constants/app_constants.dart';
import 'config/env.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'data/local/app_database.dart';
import 'data/local/app_preferences.dart';
import 'data/local/secure_session_storage.dart';
import 'data/repositories/cie10_repository.dart';
import 'data/repositories/drift_cie10_repository.dart';
import 'data/repositories/in_memory_cie10_repository.dart';
import 'data/repositories/supabase_admin_repository.dart';
import 'data/repositories/supabase_appointment_repository.dart';
import 'data/repositories/supabase_auth_repository.dart';
import 'data/repositories/supabase_doctor_repository.dart';
import 'data/repositories/supabase_reception_repository.dart';
import 'providers/admin_provider.dart';
import 'providers/app_startup_notifier.dart';
import 'providers/appointment_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/doctor_provider.dart';
import 'providers/reception_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.validate();
  await initializeDateFormatting('es_CO');
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
    // Android: sesión cifrada. Web: almacenamiento por defecto del navegador.
    authOptions: FlutterAuthClientOptions(
      localStorage: kIsWeb ? null : SecureSessionStorage(),
    ),
  );

  final preferences = AppPreferences();
  final isFirstLaunch = !await preferences.hasSeenIntro();
  final authProvider = AuthProvider(
    SupabaseAuthRepository(Supabase.instance.client),
  );
  runApp(
    ClinicaPlusApp(
      authProvider: authProvider,
      preferences: preferences,
      isFirstLaunch: isFirstLaunch,
    ),
  );
}

class ClinicaPlusApp extends StatefulWidget {
  const ClinicaPlusApp({
    super.key,
    required this.authProvider,
    required this.preferences,
    required this.isFirstLaunch,
  });

  final AuthProvider authProvider;
  final AppPreferences preferences;
  final bool isFirstLaunch;

  @override
  State<ClinicaPlusApp> createState() => _ClinicaPlusAppState();
}

class _ClinicaPlusAppState extends State<ClinicaPlusApp> {
  late final AppStartupNotifier _startup = AppStartupNotifier(
    isFirstLaunch: widget.isFirstLaunch,
  );

  // Se crea una sola vez para no perder el estado de navegación.
  late final GoRouter _router = buildAppRouter(
    auth: widget.authProvider,
    startup: _startup,
  );

  @override
  void dispose() {
    _router.dispose();
    _startup.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: widget.authProvider),
      ChangeNotifierProvider<AppStartupNotifier>.value(value: _startup),
      Provider<AppPreferences>.value(value: widget.preferences),
      ChangeNotifierProvider<AppointmentProvider>(
        create: (_) => AppointmentProvider(
          SupabaseAppointmentRepository(Supabase.instance.client),
        ),
      ),
      ChangeNotifierProvider<ReceptionProvider>(
        create: (_) => ReceptionProvider(
          SupabaseReceptionRepository(Supabase.instance.client),
        ),
      ),
      // CIE-10 local: SQLite (drift) en Android; en memoria en web.
      Provider<Cie10Repository>(
        create: (_) => kIsWeb
            ? InMemoryCie10Repository()
            : DriftCie10Repository(AppDatabase()),
      ),
      ChangeNotifierProvider<DoctorProvider>(
        create: (_) =>
            DoctorProvider(SupabaseDoctorRepository(Supabase.instance.client)),
      ),
      ChangeNotifierProvider<MedicalRecordsProvider>(
        create: (_) => MedicalRecordsProvider(
          SupabaseDoctorRepository(Supabase.instance.client),
        ),
      ),
      // Lazy: solo se crea cuando un admin abre el módulo.
      ChangeNotifierProvider<AdminProvider>(
        create: (_) =>
            AdminProvider(SupabaseAdminRepository(Supabase.instance.client)),
      ),
    ],
    child: MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: _router,
    ),
  );
}
