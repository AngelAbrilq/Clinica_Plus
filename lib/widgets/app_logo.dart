import 'package:material_ui/material_ui.dart';

import '../config/constants/app_constants.dart';

/// Logo de la app. Usa [Hero] para "volar" entre el splash y el login.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 76});

  static const String heroTag = 'clinica-plus-logo';
  static const Color _blueLight = Color(0xFF42A5F5);
  static const Color _blueDark = Color(0xFF1565C0);

  final double size;

  @override
  Widget build(BuildContext context) => Hero(
    tag: heroTag,
    child: Semantics(
      label: AppConstants.appName,
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_blueLight, _blueDark],
          ),
          boxShadow: [
            BoxShadow(
              color: _blueDark.withValues(alpha: 0.45),
              blurRadius: size * 0.3,
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: Icon(
          Icons.local_hospital_rounded,
          color: Colors.white,
          size: size * 0.56,
        ),
      ),
    ),
  );
}
