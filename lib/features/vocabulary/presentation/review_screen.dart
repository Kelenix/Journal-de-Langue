import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../billing/application/billing_providers.dart';
import '../../export/application/export_providers.dart';
import '../../export/domain/export_period.dart';
import '../application/vocabulary_providers.dart';
import '../domain/vocabulary_item.dart';

/// Exercices, puis mots et expressions à réviser tirés des journaux corrigés
/// (US-08, US-14).
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabReview),
        actions: const [_ExportAction()],
      ),
      body: SafeArea(
        child: AsyncView(
          value: ref.watch(vocabularyProvider),
          onRetry: () => ref.invalidate(vocabularyProvider),
          builder: (items) => _ReviewList(items: items),
        ),
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  const _ReviewList({required this.items});

  final List<VocabularyItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Les mots à réviser d'abord, les mots appris ensuite.
    final toReview = items.where((item) => item.learnedAt == null);
    final learned = items.where((item) => item.learnedAt != null);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: const Icon(Icons.quiz_outlined),
            title: Text(l10n.exercisesTitle),
            subtitle: Text(l10n.exercisesCardBody),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.exercises),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (items.isEmpty)
          EmptyState(icon: Icons.style_outlined, message: l10n.reviewEmpty)
        else ...[
          Text(
            l10n.reviewLearnedCount(learned.length),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in [...toReview, ...learned])
            _VocabularyCard(key: ValueKey(item.id), item: item),
        ],
      ],
    );
  }
}

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
    final isLearned = item.learnedAt != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.term, style: theme.textTheme.titleMedium),
                  Text(item.translation),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.example,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: isLearned
                  ? l10n.reviewMarkToReview
                  : l10n.reviewMarkLearned,
              isSelected: isLearned,
              icon: const Icon(Icons.check_circle_outline),
              selectedIcon: Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
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
      icon: const Icon(Icons.picture_as_pdf_outlined),
      onPressed: () => _export(context, ref),
    );
  }
}
