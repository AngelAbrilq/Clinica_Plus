import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema Material 3 azul médico (claro/oscuro) basado en FlexColorScheme.
abstract final class AppTheme {
  static const FlexScheme _scheme = FlexScheme.blueM3;

  static const FlexSubThemesData _subThemes = FlexSubThemesData(
    defaultRadius: 14,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    inputDecoratorRadius: 12,
    elevatedButtonSchemeColor: SchemeColor.onPrimary,
    elevatedButtonSecondarySchemeColor: SchemeColor.primary,
    navigationBarIndicatorSchemeColor: SchemeColor.primaryContainer,
  );

  static ThemeData get light => FlexThemeData.light(
        scheme: _scheme,
        subThemesData: _subThemes,
        visualDensity: VisualDensity.standard,
        fontFamily: GoogleFonts.nunito().fontFamily,
      );

  static ThemeData get dark => FlexThemeData.dark(
        scheme: _scheme,
        subThemesData: _subThemes,
        visualDensity: VisualDensity.standard,
        fontFamily: GoogleFonts.nunito().fontFamily,
      );
}
