import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Carte de contenu : fond blanc, grands arrondis, ombre douce.
class SoftCard extends StatelessWidget {
  const SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.card,
    this.color,
    this.elevated = true,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Fond de la carte : blanc (`cardColor`) par défaut.
  final Color? color;

  /// Ombre douce sous la carte.
  final bool elevated;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: elevated ? theme.extension<AppColors>()!.softShadow : null,
      ),
      child: Material(
        color: color ?? theme.cardColor,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: _tappable(onTap, Padding(padding: padding, child: child)),
      ),
    );
  }
}

/// Aplat vert de la marque pour les contenus mis en avant. Textes, icônes et
/// bouton principal y passent en ivoire.
class HeroCard extends StatelessWidget {
  const HeroCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.card)),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: colors.onHero,
          onPrimary: colors.hero,
          onSurface: colors.onHero,
          onSurfaceVariant: colors.onHeroMuted,
        ),
        textTheme: theme.textTheme.apply(
          bodyColor: colors.onHero,
          displayColor: colors.onHero,
        ),
        iconTheme: theme.iconTheme.copyWith(color: colors.onHero),
      ),
      child: Material(
        color: colors.hero,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: _tappable(onTap, Padding(padding: padding, child: child)),
      ),
    );
  }
}

/// Une carte qui s'ouvre au toucher est annoncée comme un seul bouton.
Widget _tappable(VoidCallback? onTap, Widget child) => onTap == null
    ? child
    : MergeSemantics(
        child: Semantics(
          button: true,
          child: InkWell(onTap: onTap, child: child),
        ),
      );
