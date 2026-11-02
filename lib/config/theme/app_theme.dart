import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Sistema visual de Clinica Plus (Material 3, claro y oscuro).
/// Tipografía: Plus Jakarta Sans. Superficies con borde fino en lugar
/// de sombras; radios mayores en lo importante (tickets, diálogos).
abstract final class AppTheme {
  static const double radiusSmall = 12;
  static const double radiusMedium = 18;
  static const double radiusLarge = 26;

  static ThemeData get light => _build(_lightScheme);
  static ThemeData get dark => _build(_darkScheme);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.azulPlus,
    onPrimary: Colors.white,
    primaryContainer: AppColors.bruma,
    onPrimaryContainer: Color(0xFF0A3D8F),
    secondary: Color(0xFF3D5A80),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFDDE7F3),
    onSecondaryContainer: AppColors.tinta,
    tertiary: AppColors.menta,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFD3F9E8),
    onTertiaryContainer: Color(0xFF06603F),
    error: AppColors.coral,
    onError: Colors.white,
    errorContainer: Color(0xFFFFE3E3),
    onErrorContainer: Color(0xFF8A1C1C),
    surface: AppColors.algodon,
    onSurface: AppColors.tinta,
    onSurfaceVariant: Color(0xFF52667A),
    outline: Color(0xFFB4C2D3),
    outlineVariant: Color(0xFFDCE4EE),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFEEF3F9),
    surfaceContainer: Color(0xFFE8EFF7),
    surfaceContainerHigh: Color(0xFFE1E9F3),
    surfaceContainerHighest: Color(0xFFD9E3EF),
    inverseSurface: AppColors.tinta,
    onInverseSurface: AppColors.algodon,
    inversePrimary: AppColors.azulNoche,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.azulNoche,
    onPrimary: Color(0xFF002A66),
    primaryContainer: Color(0xFF12407F),
    onPrimaryContainer: Color(0xFFD6E6FF),
    secondary: Color(0xFFA9BCD4),
    onSecondary: Color(0xFF1B2F48),
    secondaryContainer: Color(0xFF243A57),
    onSecondaryContainer: Color(0xFFDDE7F3),
    tertiary: Color(0xFF63E6BE),
    onTertiary: Color(0xFF003826),
    tertiaryContainer: Color(0xFF0B5C43),
    onTertiaryContainer: Color(0xFFC3FAE8),
    error: Color(0xFFFF8787),
    onError: Color(0xFF5C0A0A),
    errorContainer: Color(0xFF7A1C1C),
    onErrorContainer: Color(0xFFFFE3E3),
    surface: AppColors.nocheClinica,
    onSurface: Color(0xFFE6EEF8),
    onSurfaceVariant: Color(0xFF9FB3C8),
    outline: Color(0xFF3A4F6B),
    outlineVariant: Color(0xFF22344F),
    surfaceContainerLowest: Color(0xFF0F1D33),
    surfaceContainerLow: Color(0xFF122139),
    surfaceContainer: Color(0xFF13233D),
    surfaceContainerHigh: Color(0xFF1A2C49),
    surfaceContainerHighest: Color(0xFF223656),
    inverseSurface: Color(0xFFE6EEF8),
    onInverseSurface: AppColors.nocheClinica,
    inversePrimary: AppColors.azulPlus,
  );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    final textTheme = text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: text.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.45),
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(color: color, width: width),
        );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusSmall),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: inputBorder(scheme.outline),
        enabledBorder: inputBorder(scheme.outlineVariant),
        focusedBorder: inputBorder(scheme.primary, 2),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: buttonShape,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: buttonShape,
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        // Seleccionado = Bruma + texto oscuro: contraste AA en ambos modos.
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.primary,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        labelStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLarge),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: scheme.primary,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        dividerColor: scheme.outlineVariant,
        labelStyle: textTheme.labelLarge,
      ),
      listTileTheme: ListTileThemeData(iconColor: scheme.onSurfaceVariant),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
        ),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
