import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/surfaces.dart';
import '../domain/journal_entry.dart';
import 'category_labels.dart';

/// Une faute relevée : le fragment fautif barré, sa correction et l'explication.
/// La couleur n'est jamais seule : la faute est aussi barrée.
class CorrectionItemCard extends StatelessWidget {
  const CorrectionItemCard({
    required this.item,
    this.showsCategory = false,
    super.key,
  });

  final CorrectionItem item;
  final bool showsCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return SoftCard(
      radius: AppRadius.tile,
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showsCategory) ...[
            Tag(errorCategoryName(l10n, item.category)),
            const SizedBox(height: AppSpacing.md),
          ],
          Semantics(
            label: l10n.correctionItemLabel(item.original, item.corrected),
            excludeSemantics: true,
            child: Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  item.original,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: colors.mistake,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: colors.mistake,
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                Text(
                  item.corrected,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.fix,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.explanation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
