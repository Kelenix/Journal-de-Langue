import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';

/// Symbole, nom et signature de la marque, posés sur l'aplat vert.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  /// Généré par tool/generate_app_icons.py.
  static const _logoAsset = 'assets/brand/logo.png';
  static const _logoSize = 88.0;
  static const _ringWidth = 6.0;
  static const _ringOpacity = 0.12;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Le logo, du même vert que l'aplat, est détaché par un liseré clair.
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sheet),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(
                alpha: _ringOpacity,
              ),
              width: _ringWidth,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Image.asset(
              _logoAsset,
              width: _logoSize,
              height: _logoSize,
              excludeFromSemantics: true,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.appTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
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
