import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../languages/domain/learning_language.dart';
import '../../voice/presentation/voice_buttons.dart';
import '../domain/journal_entry.dart';
import 'category_labels.dart';

/// Une faute relevée : le fragment fautif barré, sa correction et l'explication.
/// La couleur n'est jamais seule : la faute est aussi barrée.
class CorrectionItemCard extends StatelessWidget {
  const CorrectionItemCard({
    required this.item,
    this.showsCategory = false,
    this.listen,
    super.key,
  });

  final CorrectionItem item;
  final bool showsCategory;

  /// Phrase corrigée à lire à voix haute (Premium), sinon pas de bouton.
  final ({String text, LearningLanguage language})? listen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final listen = this.listen;

    return SoftCard(
      radius: AppRadius.tile,
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showsCategory || listen != null) ...[
            Row(
              children: [
                if (showsCategory) Tag(errorCategoryName(l10n, item.category)),
                const Spacer(),
                if (listen != null)
                  ListenButton(text: listen.text, language: listen.language),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Semantics(
            label: l10n.correctionItemLabel(item.original, item.corrected),
            excludeSemantics: true,
            child: Wrap(
              spacing: AppSpacing.md,
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
