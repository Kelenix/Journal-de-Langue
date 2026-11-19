import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_view.dart';
import '../application/journal_providers.dart';
import '../domain/journal_entry.dart';
import 'category_labels.dart';
import 'highlighted_text.dart';
import 'rewrite_section.dart';

/// Correction d'un journal : version d'origine, version corrigée, explications.
class CorrectionScreen extends ConsumerWidget {
  const CorrectionScreen({required this.entryId, super.key});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.correctionTitle)),
      body: SafeArea(
        child: AsyncView(
          value: ref.watch(journalEntryProvider(entryId)),
          onRetry: () => ref.invalidate(journalEntryProvider(entryId)),
          builder: (entry) => _CorrectionContent(entry: entry),
        ),
      ),
    );
  }
}

class _CorrectionContent extends StatelessWidget {
  const _CorrectionContent({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final items = entry.items;
    final isAdvanced = entry.level == CorrectionLevel.advanced;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (isAdvanced)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Chip(label: Text(l10n.correctionAdvanced)),
            ),
          ),
        _SectionTitle(l10n.correctionYourVersion),
        // Jamais la couleur seule : la faute est aussi barrée.
        HighlightedText(
          text: entry.originalText,
          fragments: [for (final item in items) item.original],
          highlightStyle: TextStyle(
            color: colors.mistake,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(l10n.correctionCorrectedVersion),
        HighlightedText(
          text: entry.correctedText,
          fragments: [for (final item in items) item.corrected],
          highlightStyle: TextStyle(
            color: colors.fix,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(
          items.isEmpty
              ? l10n.correctionNoMistakes
              : l10n.correctionPointsTitle(items.length),
        ),
        if (items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              l10n.correctionEncouragement,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final item in items)
          // Premium : chaque faute est classée par catégorie (US-12).
          _CorrectionItemCard(item: item, showsCategory: isAdvanced),
        if (entry.vocabulary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(l10n.correctionVocabularyTitle),
          Card(
            child: Column(
              children: [
                for (final word in entry.vocabulary)
                  ListTile(
                    title: Text(word.term),
                    subtitle: Text(word.translation),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        RewriteSection(entry: entry),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: () => context.pop(),
          child: Text(l10n.correctionDone),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _CorrectionItemCard extends StatelessWidget {
  const _CorrectionItemCard({required this.item, required this.showsCategory});

  final CorrectionItem item;
  final bool showsCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showsCategory)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  errorCategoryName(l10n, item.category),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Semantics(
              label: l10n.correctionItemLabel(item.original, item.corrected),
              excludeSemantics: true,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: item.original,
                      style: TextStyle(
                        color: colors.mistake,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const TextSpan(text: '  →  '),
                    TextSpan(
                      text: item.corrected,
                      style: TextStyle(
                        color: colors.fix,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(item.explanation),
          ],
        ),
      ),
    );
  }
}
