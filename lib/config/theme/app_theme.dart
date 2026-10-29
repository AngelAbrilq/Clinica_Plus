import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// Tema Material 3 azul médico (claro/oscuro) basado en FlexColorScheme 9.
abstract final class AppTheme {
  static const FlexScheme _scheme = FlexScheme.blue;

  static const FlexSubThemesData _subThemes = FlexSubThemesData(
    defaultRadius: 14,
    inputDecoratorBorderType: FlexInputBorderType.outline,
  );

  static ThemeData get light => FlexThemeData.light(
        scheme: _scheme,
        subThemesData: _subThemes,
        fontFamily: GoogleFonts.nunito().fontFamily,
      );

  static ThemeData get dark => FlexThemeData.dark(
        scheme: _scheme,
        subThemesData: _subThemes,
        fontFamily: GoogleFonts.nunito().fontFamily,
      );
}
