import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../application/stats_providers.dart';

/// Série de jours en cours, rappelée sur l'écran Journal. Rien tant qu'elle
/// n'a pas commencé, ni pendant le chargement.
class StreakBadge extends ConsumerWidget {
  const StreakBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(statsProvider).value?.streakDays ?? 0;
    if (days == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(Icons.local_fire_department, color: colors.accent),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            AppLocalizations.of(context).journalStreak(days),
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
