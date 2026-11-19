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
      appBar: AppBar(title: Text(l10n.tabReview)),
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
