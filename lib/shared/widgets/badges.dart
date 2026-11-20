import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Icône décorative sur une pastille arrondie teintée.
class IconBadge extends StatelessWidget {
  const IconBadge(
    this.icon, {
    this.size = 40,
    this.warm = false,
    this.accent = false,
    this.color,
    super.key,
  });

  static const _cornerRatio = 0.3;
  static const _iconRatio = 0.5;
  static const _tintOpacity = 0.12;

  final IconData icon;
  final double size;

  /// Corail doux au lieu du vert.
  final bool warm;

  /// Corail plein, pour une pastille posée sur une carte corail douce.
  final bool accent;

  /// Teinte imposée (par exemple l'erreur pour une action destructrice).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<AppColors>()!;
    final color = this.color;
    final (background, foreground) = switch ((color, warm)) {
      (final Color tint?, _) => (tint.withValues(alpha: _tintOpacity), tint),
      _ when accent => (colors.accent, colors.onAccent),
      (null, true) => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      (null, false) => (scheme.primaryContainer, scheme.onPrimaryContainer),
    };
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size * _cornerRatio),
        ),
        child: Icon(icon, size: size * _iconRatio, color: foreground),
      ),
    );
  }
}

/// Barre de progression arrondie, en corail. Décorative : le texte qui
/// l'accompagne porte l'information.
class SoftProgressBar extends StatelessWidget {
  const SoftProgressBar({required this.value, this.color, super.key});

  static const _height = 8.0;

  /// Avancement, entre 0 et 1.
  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExcludeSemantics(
      child: LinearProgressIndicator(
        value: value.clamp(0, 1).toDouble(),
        minHeight: _height,
        borderRadius: BorderRadius.circular(_height / 2),
        backgroundColor: theme.colorScheme.surfaceContainer,
        color: color ?? theme.extension<AppColors>()!.accent,
      ),
    );
  }
}

/// Étiquette arrondie et teintée : catégorie de faute, niveau, statut.
class Tag extends StatelessWidget {
  const Tag(this.label, {this.warm = false, super.key});

  final String label;

  /// Corail doux au lieu du vert.
  final bool warm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: warm ? scheme.secondaryContainer : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: warm
                ? scheme.onSecondaryContainer
                : scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
