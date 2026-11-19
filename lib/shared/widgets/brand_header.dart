import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';

/// Symbole, nom et signature de la marque.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  /// Généré par tool/generate_app_icons.py.
  static const _logoAsset = 'assets/brand/logo.png';
  static const _logoSize = 72.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Image.asset(
            _logoAsset,
            width: _logoSize,
            height: _logoSize,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.appTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.appTagline,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
