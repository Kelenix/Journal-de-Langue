import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../journal/application/journal_providers.dart';
import '../../journal/domain/journal_entry.dart';

/// Journaux corrigés que l'offre permet de relire (US-09).
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabHistory)),
      body: SafeArea(
        child: AsyncView(
          value: ref.watch(journalHistoryProvider),
          onRetry: () => ref.invalidate(journalHistoryProvider),
          builder: (history) =>
              history.entries.isEmpty && history.overview.lockedEntries == 0
              ? EmptyState(
                  icon: Icons.history_outlined,
                  message: l10n.historyEmpty,
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    for (final entry in history.entries)
                      _HistoryCard(entry: entry),
                    if (history.overview.lockedEntries > 0)
                      _LockedNotice(overview: history.overview),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  static const _excerptLines = 2;

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        title: Text(
          MaterialLocalizations.of(context).formatFullDate(entry.entryDate),
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text(
              entry.originalText,
              maxLines: _excerptLines,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.historyMistakes(entry.items.length),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.correctionOf(entry.id)),
      ),
    );
  }
}

/// Journaux plus anciens que la fenêtre de l'offre : conservés, non lisibles.
class _LockedNotice extends StatelessWidget {
  const _LockedNotice({required this.overview});

  final HistoryOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.lock_outline,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '${l10n.historyLocked(overview.lockedEntries)} '
              '${l10n.historyWindow(overview.historyDays)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
