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
    required this.hero,
    required this.onHero,
    required this.onHeroMuted,
    required this.shadow,
  });

  static const light = AppColors(
    mistake: Color(0xFFB3261E),
    fix: BrandColors.deepGreen,
    accent: BrandColors.coral,
    onAccent: BrandColors.darkText,
    hero: BrandColors.deepGreen,
    onHero: BrandColors.ivory,
    onHeroMuted: Color(0xFFD7E6E0),
    shadow: Color(0x1F174D43),
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

  /// Grands aplats de la marque : en-têtes et cartes mises en avant.
  final Color hero;

  /// Texte posé sur [hero].
  final Color onHero;

  /// Texte secondaire posé sur [hero].
  final Color onHeroMuted;

  /// Ombre douce des cartes et de la barre d'onglets.
  final Color shadow;

  /// Ombre des éléments posés sur le fond (cartes, barre d'onglets).
  List<BoxShadow> get softShadow => [
    BoxShadow(color: shadow, blurRadius: 30, offset: const Offset(0, 10)),
  ];

  @override
  AppColors copyWith({
    Color? mistake,
    Color? fix,
    Color? accent,
    Color? onAccent,
    Color? hero,
    Color? onHero,
    Color? onHeroMuted,
    Color? shadow,
  }) => AppColors(
    mistake: mistake ?? this.mistake,
    fix: fix ?? this.fix,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    hero: hero ?? this.hero,
    onHero: onHero ?? this.onHero,
    onHeroMuted: onHeroMuted ?? this.onHeroMuted,
    shadow: shadow ?? this.shadow,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      mistake: Color.lerp(mistake, other.mistake, t)!,
      fix: Color.lerp(fix, other.fix, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      hero: Color.lerp(hero, other.hero, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      onHeroMuted: Color.lerp(onHeroMuted, other.onHeroMuted, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}
