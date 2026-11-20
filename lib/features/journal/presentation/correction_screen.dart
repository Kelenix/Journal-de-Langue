import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../billing/application/billing_providers.dart';
import '../../reports/domain/content_report_repository.dart';
import '../../reports/presentation/report_content_button.dart';
import '../../vocabulary/domain/vocabulary_item.dart';
import '../../voice/presentation/voice_buttons.dart';
import '../application/journal_providers.dart';
import '../domain/journal_entry.dart';
import 'correction_item_card.dart';
import 'highlighted_text.dart';
import 'rewrite_section.dart';

/// Correction d'un journal : bilan, version d'origine ou corrigée,
/// explications, mots à réviser et reformulations.
class CorrectionScreen extends ConsumerWidget {
  const CorrectionScreen({required this.entryId, super.key});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: SoftAppBar(
        title: l10n.correctionTitle,
        actions: [
          ReportContentButton(
            content: ReportedContent.correction,
            targetId: entryId,
            style: roundButtonStyle(context),
          ),
        ],
      ),
      body: AsyncView(
        value: ref.watch(journalEntryProvider(entryId)),
        onRetry: () => ref.invalidate(journalEntryProvider(entryId)),
        builder: (entry) => _CorrectionContent(entry: entry),
      ),
    );
  }
}

class _CorrectionContent extends ConsumerWidget {
  const _CorrectionContent({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = entry.items;
    final isAdvanced = entry.level == CorrectionLevel.advanced;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              _Summary(mistakes: items.length, isAdvanced: isAdvanced),
              const SizedBox(height: AppSpacing.lg),
              _Versions(
                entry: entry,
                canListen: watchActiveSubscription(ref) != null,
              ),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  // Premium : chaque faute est classée par catégorie (US-12).
                  child: CorrectionItemCard(
                    item: item,
                    showsCategory: isAdvanced,
                  ),
                ),
              if (entry.vocabulary.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                SectionTitle(l10n.correctionVocabularyTitle),
                _VocabularyChips(words: entry.vocabulary),
              ],
              const SizedBox(height: AppSpacing.xl),
              RewriteSection(entry: entry),
            ],
          ),
        ),
        // Toujours à portée de main, en bas de l'écran.
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.pop(),
              child: Text(l10n.correctionDone),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bilan sur l'aplat vert : nombre de fautes et encouragement.
class _Summary extends StatelessWidget {
  const _Summary({required this.mistakes, required this.isAdvanced});

  static const _ringSize = 64.0;
  static const _ringWidth = 6.0;

  final int mistakes;
  final bool isAdvanced;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return HeroCard(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final colors = theme.extension<AppColors>()!;
          return Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: _ringSize,
                  height: _ringSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.accent, width: _ringWidth),
                  ),
                  child: mistakes == 0
                      ? const Icon(Icons.check)
                      : Text('$mistakes', style: theme.textTheme.headlineSmall),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAdvanced) ...[
                      Tag(l10n.correctionAdvanced, warm: true),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Semantics(
                      header: true,
                      child: Text(
                        mistakes == 0
                            ? l10n.correctionNoMistakes
                            : l10n.correctionPointsTitle(mistakes),
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    if (mistakes > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.correctionEncouragement,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Version d'origine (fautes barrées) ou corrigée (corrections soulignées).
/// La couleur n'est jamais seule à porter l'information.
class _Versions extends StatefulWidget {
  const _Versions({required this.entry, required this.canListen});

  final JournalEntry entry;

  /// Lecture à voix haute réservée à Premium (US-15).
  final bool canListen;

  @override
  State<_Versions> createState() => _VersionsState();
}

class _VersionsState extends State<_Versions> {
  bool _showsCorrected = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColors>()!;
    final entry = widget.entry;
    final items = entry.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: false,
              label: Text(l10n.correctionYourVersion),
            ),
            ButtonSegment(
              value: true,
              label: Text(l10n.correctionCorrectedVersion),
            ),
          ],
          selected: {_showsCorrected},
          onSelectionChanged: (selection) =>
              setState(() => _showsCorrected = selection.single),
        ),
        const SizedBox(height: AppSpacing.md),
        SoftCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _showsCorrected
                    ? HighlightedText(
                        text: entry.correctedText,
                        fragments: [for (final item in items) item.corrected],
                        highlightStyle: TextStyle(
                          color: colors.fix,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: colors.fix,
                        ),
                      )
                    : HighlightedText(
                        text: entry.originalText,
                        fragments: [for (final item in items) item.original],
                        highlightStyle: TextStyle(
                          color: colors.mistake,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: colors.mistake,
                        ),
                      ),
              ),
              if (_showsCorrected && widget.canListen) ...[
                const SizedBox(width: AppSpacing.sm),
                ListenButton(
                  text: entry.correctedText,
                  language: entry.language,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Mots relevés dans le journal, avec leur traduction.
class _VocabularyChips extends StatelessWidget {
  const _VocabularyChips({required this.words});

  final List<VocabularyItem> words;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final word in words)
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    word.term,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    word.translation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
