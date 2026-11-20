import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';

/// Symbole, nom et signature de la marque, posés sur l'aplat vert.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  static const _logoSize = 104.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandLogo(size: _logoSize),
        const SizedBox(height: AppSpacing.xl),
        Semantics(
          header: true,
          child: Text(
            l10n.appTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.appTagline,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Symbole de la marque, carré aux coins arrondis.
class BrandLogo extends StatelessWidget {
  const BrandLogo({required this.size, super.key});

  /// Généré par tool/generate_app_icons.py, sur un fond plus foncé que l'aplat.
  static const _asset = 'assets/brand/logo.png';

  // Coins à l'échelle du logo : 28 points pour sa taille sur l'accueil (104).
  static const _cornerRatio = AppRadius.sheet / 104;

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * _cornerRatio),
    child: Image.asset(
      _asset,
      width: size,
      height: size,
      excludeFromSemantics: true,
    ),
  );
}
