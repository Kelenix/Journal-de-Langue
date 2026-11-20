import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Thème de l'application, construit sur le brand kit : vert profond, ivoire,
/// corail ; titres en DM Sans, texte en Inter. Grandes cartes arrondies à
/// l'ombre douce, boutons pleins et généreux.
abstract final class AppTheme {
  static const titleFont = 'DM Sans';
  static const bodyFont = 'Inter';

  /// Barres du système transparentes et sans voile : l'app se dessine dessous
  /// (bord à bord) et garde sa couleur jusqu'en bas de l'écran (ADR-042).
  static const systemBars = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  /// Même chose sous un aplat vert en haut de l'écran : icônes claires.
  static final systemBarsOnHero = systemBars.copyWith(
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  static const _journalLineHeight = 1.55;
  static const _buttonHeight = 56.0;
  static const _secondaryButtonHeight = 52.0;
  static const _minTouchTarget = 48.0;
  static const _softBorderOpacity = 0.3;

  // Le gris du brand kit (#788680) ne suffit pas pour du petit texte sur
  // ivoire (contraste 3,5) : le texte secondaire utilise un gris plus foncé.
  static const _secondaryTextLight = Color(0xFF5C6B65);

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
      surfaceContainer: const Color(0xFFEFEBDF),
      surfaceContainerHigh: const Color(0xFFEBE8DB),
      surfaceContainerHighest: const Color(0xFFE5E1D3),
      outline: BrandColors.softGray,
      outlineVariant: const Color(0xFFE4E0D3),
      error: const Color(0xFFB3261E),
      onError: BrandColors.white,
      inverseSurface: BrandColors.darkText,
      onInverseSurface: BrandColors.ivory,
    ),
    cardColor: BrandColors.white,
    colors: AppColors.light,
  );

  static ThemeData _build(
    ColorScheme scheme, {
    required Color cardColor,
    required AppColors colors,
  }) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final textTheme = _textTheme(base.textTheme, scheme);
    final buttonText = textTheme.labelLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

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
      cardColor: cardColor,
      extensions: [colors],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium?.copyWith(fontSize: 18),
      ),
      // Les cartes ombrées passent par SoftCard ; Card, à plat, sert aux
      // listes de choix.
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.tile)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        border: fieldBorder(scheme.outlineVariant),
        enabledBorder: fieldBorder(scheme.outlineVariant),
        focusedBorder: fieldBorder(scheme.primary, 2),
        errorBorder: fieldBorder(scheme.error),
        focusedErrorBorder: fieldBorder(scheme.error, 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(_buttonHeight),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      // Boutons secondaires : fond transparent, bordure vert doux.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(_secondaryButtonHeight),
          shape: buttonShape,
          foregroundColor: scheme.primary,
          side: BorderSide(
            color: scheme.primary.withValues(alpha: _softBorderOpacity),
          ),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(_minTouchTarget, _minTouchTarget),
          textStyle: buttonText?.copyWith(fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.primaryContainer,
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.chip)),
        ),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: cardColor,
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          side: BorderSide(color: scheme.outlineVariant),
          minimumSize: const Size.fromHeight(_minTouchTarget),
          textStyle: textTheme.labelLarge,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: colors.accent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.chip)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.sheet)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.tile)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainer,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.surfaceContainer,
        space: 1,
        thickness: 1,
      ),
    );
  }

  /// Titres en DM Sans gras et resserrés, contenu en Inter (Regular, Medium
  /// pour les libellés).
  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    final body = base.apply(
      fontFamily: bodyFont,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    TextStyle? title(TextStyle? style, {double? size, double spacing = 0}) =>
        style?.copyWith(
          fontFamily: titleFont,
          fontWeight: FontWeight.w700,
          fontSize: size,
          letterSpacing: spacing,
        );
    TextStyle? label(TextStyle? style) =>
        style?.copyWith(fontWeight: FontWeight.w500);

    return body.copyWith(
      displaySmall: title(body.displaySmall, size: 40, spacing: -0.5),
      headlineLarge: title(body.headlineLarge, size: 34, spacing: -0.5),
      headlineMedium: title(body.headlineMedium, size: 30, spacing: -0.5),
      headlineSmall: title(body.headlineSmall, size: 24),
      titleLarge: title(body.titleLarge, size: 20),
      titleMedium: title(body.titleMedium, size: 17),
      titleSmall: title(body.titleSmall, size: 15),
      bodyLarge: body.bodyLarge?.copyWith(height: _journalLineHeight),
      labelLarge: label(body.labelLarge),
      labelMedium: label(body.labelMedium),
      labelSmall: label(body.labelSmall),
    );
  }
}
