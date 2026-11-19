import 'package:flutter/material.dart';

/// Palette du brand kit (docs/design/design-system.md).
abstract final class BrandColors {
  static const deepGreen = Color(0xFF174D43);
  static const ivory = Color(0xFFF7F4EA);
  static const coral = Color(0xFFF2A38A);
  static const darkText = Color(0xFF20332E);
  static const white = Color(0xFFFFFFFF);
  static const softGray = Color(0xFF788680);
}

/// Couleurs porteuses de sens, absentes du `ColorScheme` Material.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.mistake,
    required this.fix,
    required this.accent,
    required this.onAccent,
  });

  static const light = AppColors(
    mistake: Color(0xFFB3261E),
    fix: BrandColors.deepGreen,
    accent: BrandColors.coral,
    onAccent: BrandColors.darkText,
  );

  static const dark = AppColors(
    mistake: Color(0xFFF2B8B5),
    fix: Color(0xFF8FCDBD),
    accent: BrandColors.coral,
    onAccent: BrandColors.darkText,
  );

  /// Fragment fautif ; toujours accompagné d'un texte barré.
  final Color mistake;

  /// Fragment corrigé ; toujours accompagné d'un soulignement.
  final Color fix;

  /// Corail de la marque : accents visuels et progression, jamais du texte
  /// (contraste insuffisant sur fond ivoire).
  final Color accent;

  /// Texte ou icône posé sur [accent].
  final Color onAccent;

  @override
  AppColors copyWith({
    Color? mistake,
    Color? fix,
    Color? accent,
    Color? onAccent,
  }) => AppColors(
    mistake: mistake ?? this.mistake,
    fix: fix ?? this.fix,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      mistake: Color.lerp(mistake, other.mistake, t)!,
      fix: Color.lerp(fix, other.fix, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}
