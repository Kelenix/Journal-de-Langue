import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../billing/application/billing_providers.dart';
import '../../journal/application/journal_providers.dart';
import '../../export/application/export_providers.dart';
import '../../export/domain/export_period.dart';
import '../application/vocabulary_providers.dart';
import '../domain/vocabulary_item.dart';
import 'daily_card.dart';

/// Exercices, cartes du jour, puis mots et expressions à réviser tirés des
/// journaux corrigés (US-08, US-14).
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: TabAppBar(
        title: l10n.tabReview,
        actions: const [_ExportAction()],
      ),
      body: AsyncView(
        value: ref.watch(vocabularyProvider),
        onRetry: () => ref.invalidate(vocabularyProvider),
        builder: (items) => _ReviewList(items: items),
      ),
    );
  }
}

class _ReviewList extends ConsumerWidget {
  const _ReviewList({required this.items});

  final List<VocabularyItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Payante : présentée après une première correction (INTAKE §6), ou à
    // qui a déjà un Pack Examinateur.
    final showsExam =
        watchHasCorrectedJournal(ref) ||
        (ref.watch(walletProvider).value?.examCredits ?? 0) > 0;
    // Les mots à réviser d'abord, les mots appris ensuite.
    final toReview = items.where((item) => item.learnedAt == null);
    final learned = items.where((item) => item.learnedAt != null).toList();
    final words = [...toReview, ...learned];

    final header = [
      _PracticeTiles(showsExam: showsExam),
      const SizedBox(height: AppSpacing.xl),
      if (items.isEmpty)
        EmptyState(icon: Icons.style_outlined, message: l10n.reviewEmpty)
      else ...[
        DailyCard(words: items),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: SectionTitle(l10n.reviewWordsTitle)),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                l10n.reviewLearnedCount(learned.length),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        SoftProgressBar(value: learned.length / items.length),
        const SizedBox(height: AppSpacing.lg),
      ],
    ];

    // Construite à la demande : le vocabulaire grandit chaque jour.
    return ListView.builder(
      padding: tabPagePadding,
      itemCount: header.length + words.length,
      itemBuilder: (context, index) {
        if (index < header.length) return header[index];
        final item = words[index - header.length];
        return _VocabularyCard(key: ValueKey(item.id), item: item);
      },
    );
  }
}

/// Exercices sur l'aplat vert ; l'examen blanc, payant, à côté en corail.
class _PracticeTiles extends StatelessWidget {
  const _PracticeTiles({required this.showsExam});

  final bool showsExam;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final exercises = HeroCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: () => context.push(AppRoutes.exercises),
      child: _PracticeTileContent(
        icon: Icons.quiz_outlined,
        title: l10n.exercisesTitle,
        body: l10n.exercisesCardBody,
      ),
    );
    if (!showsExam) return exercises;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: exercises),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SoftCard(
              color: Theme.of(context).colorScheme.secondaryContainer,
              elevated: false,
              onTap: () => context.push(AppRoutes.exam),
              child: _PracticeTileContent(
                icon: Icons.school_outlined,
                title: l10n.examTitle,
                body: l10n.examCardBody,
                warm: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeTileContent extends StatelessWidget {
  const _PracticeTileContent({
    required this.icon,
    required this.title,
    required this.body,
    this.warm = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = warm ? theme.colorScheme.onSecondaryContainer : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBadge(icon, accent: warm),
        const SizedBox(height: AppSpacing.xl),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(color: textColor),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          body,
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor ?? theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Un mot à réviser : terme, traduction et exemple ; un bouton rond le marque
/// comme appris.
class _VocabularyCard extends ConsumerWidget {
  const _VocabularyCard({required this.item, super.key});

  final VocabularyItem item;

  Future<void> _toggleLearned(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(vocabularyProvider.notifier)
          .setLearned(item, isLearned: item.learnedAt == null);
    } on Failure catch (failure) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, failure))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLearned = item.learnedAt != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SoftCard(
        radius: AppRadius.tile,
        elevated: false,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.term, style: theme.textTheme.titleSmall),
                  Text(
                    item.translation,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.example,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              tooltip: isLearned
                  ? l10n.reviewMarkToReview
                  : l10n.reviewMarkLearned,
              isSelected: isLearned,
              style: isLearned
                  ? IconButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                    )
                  : IconButton.styleFrom(
                      foregroundColor: scheme.onSurfaceVariant,
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
              icon: const Icon(Icons.check),
              onPressed: () => _toggleLearned(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

/// Exporte les révisions en PDF (US-17, Premium).
class _ExportAction extends ConsumerWidget {
  const _ExportAction();

  static const _progressSize = 20.0;

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final period = await showModalBottomSheet<ExportPeriod>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l10n.exportChoosePeriod,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final (period, label) in [
              (ExportPeriod.lastWeek, l10n.exportLastWeek),
              (ExportPeriod.lastMonth, l10n.exportLastMonth),
              (ExportPeriod.allTime, l10n.exportAll),
            ])
              ListTile(
                title: Text(label),
                onTap: () => Navigator.of(sheetContext).pop(period),
              ),
          ],
        ),
      ),
    );
    if (period == null || !context.mounted) return;
    await ref.read(exportControllerProvider.notifier).export(period, l10n);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (watchActiveSubscription(ref) == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    ref.listen(exportControllerProvider, (_, next) {
      final error = next.error;
      if (error == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage(l10n, error))));
    });

    if (ref.watch(exportControllerProvider).isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: SizedBox.square(
          dimension: _progressSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            semanticsLabel: l10n.exportTitle,
          ),
        ),
      );
    }
    return IconButton(
      tooltip: l10n.exportTitle,
      style: roundButtonStyle(context),
      icon: const Icon(Icons.picture_as_pdf_outlined),
      onPressed: () => _export(context, ref),
    );
  }
}
