import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';

/// Symbole, nom et signature de la marque, posés sur l'aplat vert.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  /// Généré par tool/generate_app_icons.py, sur un fond plus foncé que l'aplat.
  static const _logoAsset = 'assets/brand/logo.png';
  static const _logoSize = 104.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          child: Image.asset(
            _logoAsset,
            width: _logoSize,
            height: _logoSize,
            excludeFromSemantics: true,
          ),
        ),
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
