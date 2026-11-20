import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_message.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../journal/application/journal_providers.dart';
import '../../journal/domain/journal_entry.dart';

/// Journaux corrigés que l'offre permet de relire (US-09), chargés par pages.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final overview = ref.watch(historyOverviewProvider).value;
    final lockedEntries = overview?.lockedEntries ?? 0;

    return Scaffold(
      appBar: TabAppBar(title: l10n.tabHistory),
      body: AsyncView(
        value: ref.watch(journalHistoryProvider),
        onRetry: () => ref.invalidate(journalHistoryProvider),
        builder: (history) {
          if (history.entries.isEmpty && lockedEntries == 0) {
            return EmptyState(
              icon: Icons.history_outlined,
              message: l10n.historyEmpty,
            );
          }
          final entries = history.entries;
          return ListView.builder(
            padding: tabPagePadding,
            // Après les journaux : la page suivante, ou ce qui est verrouillé.
            itemCount: entries.length + 1,
            itemBuilder: (context, index) => index < entries.length
                ? _HistoryCard(entry: entries[index])
                : history.hasMore
                ? _NextPage(failure: history.moreFailure)
                : overview != null && lockedEntries > 0
                ? _LockedNotice(overview: overview)
                : const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

/// Fin de la liste : charge la page suivante dès qu'elle apparaît.
class _NextPage extends ConsumerStatefulWidget {
  const _NextPage({required this.failure});

  final Failure? failure;

  @override
  ConsumerState<_NextPage> createState() => _NextPageState();
}

class _NextPageState extends ConsumerState<_NextPage> {
  @override
  void initState() {
    super.initState();
    if (widget.failure == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  void _load() {
    if (mounted) ref.read(journalHistoryProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failure = widget.failure;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: failure == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ErrorMessage(failureMessage(l10n, failure)),
                TextButton(onPressed: _load, child: Text(l10n.actionRetry)),
              ],
            ),
    );
  }
}

/// Un journal corrigé : date, début du texte et nombre de fautes.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  static const _excerptLines = 2;

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final date = entry.entryDate;
    final mistakes = entry.items.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SoftCard(
        radius: AppRadius.tile,
        elevated: false,
        onTap: () => context.push(AppRoutes.correctionOf(entry.id)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateBadge(date: date),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    toBeginningOfSentenceCase(
                      DateFormat.EEEE(l10n.localeName).format(date),
                      l10n.localeName,
                    ),
                    semanticsLabel: MaterialLocalizations.of(
                      context,
                    ).formatFullDate(date),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    entry.originalText,
                    maxLines: _excerptLines,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Tag(l10n.historyMistakes(mistakes), warm: mistakes > 0),
                ],
              ),
            ),
            ExcludeSemantics(child: Icon(Icons.chevron_right, color: muted)),
          ],
        ),
      ),
    );
  }
}

/// Jour et mois du journal, sur une pastille verte.
class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  static const _width = 52.0;

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = AppLocalizations.of(context).localeName;
    return ExcludeSemantics(
      child: Container(
        width: _width,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Column(
          children: [
            Text(
              '${date.day}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
            Text(
              DateFormat.MMM(locale).format(date),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
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
    final historyDays = overview.historyDays;
    final message = [
      l10n.historyLocked(overview.lockedEntries),
      if (historyDays != null) l10n.historyWindow(historyDays),
    ].join(' ');

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SoftCard(
        color: theme.colorScheme.secondaryContainer,
        elevated: false,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconBadge(Icons.lock_outline, accent: true),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Des journaux verrouillés existent : l'utilisateur a déjà été
            // corrigé, l'offre payante peut lui être proposée.
            FilledButton(
              onPressed: () => context.push(AppRoutes.paywall),
              child: Text(l10n.historyUnlock),
            ),
          ],
        ),
      ),
    );
  }
}
