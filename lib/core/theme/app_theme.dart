import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Thème de l'application, construit sur le brand kit : vert profond, ivoire,
/// corail ; titres en DM Sans, texte en Inter.
abstract final class AppTheme {
  static const titleFont = 'DM Sans';
  static const bodyFont = 'Inter';

  static const _journalLineHeight = 1.5;
  static const _minTouchTarget = 52.0;
  static const _softBorderOpacity = 0.4;

  // Le gris du brand kit (#788680) ne suffit pas pour du petit texte sur
  // ivoire (contraste 3,5) : le texte secondaire utilise un gris plus foncé.
  static const _secondaryTextLight = Color(0xFF5C6B65);
  static const _secondaryTextDark = Color(0xFFA3B0AB);

  static final ThemeData light = _build(
    ColorScheme.fromSeed(seedColor: BrandColors.deepGreen).copyWith(
      primary: BrandColors.deepGreen,
      onPrimary: BrandColors.ivory,
      primaryContainer: const Color(0xFFD7E6E0),
      onPrimaryContainer: const Color(0xFF0E332C),
      secondary: BrandColors.coral,
      onSecondary: BrandColors.darkText,
      secondaryContainer: const Color(0xFFFBE3D9),
      onSecondaryContainer: BrandColors.darkText,
      surface: BrandColors.ivory,
      onSurface: BrandColors.darkText,
      onSurfaceVariant: _secondaryTextLight,
      surfaceContainerLowest: BrandColors.white,
      surfaceContainerLow: const Color(0xFFFBF9F2),
      surfaceContainer: const Color(0xFFF1EEE2),
      surfaceContainerHigh: const Color(0xFFEBE8DB),
      surfaceContainerHighest: const Color(0xFFE5E1D3),
      outline: BrandColors.softGray,
      outlineVariant: const Color(0xFFD8D5C9),
      error: const Color(0xFFB3261E),
      onError: BrandColors.white,
    ),
    cardColor: BrandColors.white,
    colors: AppColors.light,
  );

  // Le brand kit ne définit que le mode clair ; le mode sombre en reprend les
  // teintes sur un fond vert très foncé.
  static final ThemeData dark = _build(
    ColorScheme.fromSeed(
      seedColor: BrandColors.deepGreen,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF8FCDBD),
      onPrimary: const Color(0xFF0B2B25),
      primaryContainer: BrandColors.deepGreen,
      onPrimaryContainer: BrandColors.ivory,
      secondary: BrandColors.coral,
      onSecondary: BrandColors.darkText,
      surface: const Color(0xFF111A17),
      onSurface: BrandColors.ivory,
      onSurfaceVariant: _secondaryTextDark,
      surfaceContainerLowest: const Color(0xFF0C1311),
      surfaceContainerLow: const Color(0xFF17211E),
      surfaceContainer: const Color(0xFF1B2623),
      surfaceContainerHigh: const Color(0xFF25312D),
      surfaceContainerHighest: const Color(0xFF303C38),
      outline: BrandColors.softGray,
      outlineVariant: const Color(0xFF3A4743),
    ),
    cardColor: const Color(0xFF1B2623),
    colors: AppColors.dark,
  );

  static ThemeData _build(
    ColorScheme scheme, {
    required Color cardColor,
    required AppColors colors,
  }) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final textTheme = _textTheme(base.textTheme, scheme);

    const fieldRadius = BorderRadius.all(Radius.circular(AppRadius.field));
    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
    );
    OutlineInputBorder fieldBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      extensions: [colors],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: fieldBorder(scheme.outlineVariant),
        enabledBorder: fieldBorder(scheme.outlineVariant),
        focusedBorder: fieldBorder(scheme.primary, 2),
        errorBorder: fieldBorder(scheme.error),
        focusedErrorBorder: fieldBorder(scheme.error, 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(_minTouchTarget),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      // Boutons secondaires du brand kit : fond ivoire, bordure vert doux.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(_minTouchTarget),
          shape: buttonShape,
          foregroundColor: scheme.primary,
          side: BorderSide(
            color: scheme.primary.withValues(alpha: _softBorderOpacity),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }

  /// Titres en DM Sans gras, contenu en Inter (Regular, Medium pour les
  /// libellés).
  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    final body = base.apply(
      fontFamily: bodyFont,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    TextStyle? title(TextStyle? style) =>
        style?.copyWith(fontFamily: titleFont, fontWeight: FontWeight.w700);
    TextStyle? label(TextStyle? style) =>
        style?.copyWith(fontWeight: FontWeight.w500);

    return body.copyWith(
      displaySmall: title(body.displaySmall),
      headlineLarge: title(body.headlineLarge),
      headlineMedium: title(body.headlineMedium),
      headlineSmall: title(body.headlineSmall),
      titleLarge: title(body.titleLarge),
      titleMedium: title(body.titleMedium),
      titleSmall: title(body.titleSmall),
      bodyLarge: body.bodyLarge?.copyWith(height: _journalLineHeight),
      labelLarge: label(body.labelLarge),
      labelMedium: label(body.labelMedium),
      labelSmall: label(body.labelSmall),
    );
  }
}
