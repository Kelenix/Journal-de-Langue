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
import '../application/journal_providers.dart';
import '../domain/journal_entry.dart';
import '../domain/sentences.dart';
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
    // Lecture à voix haute réservée à Premium (US-15) : la phrase corrigée
    // qui contient chaque correction.
    final canListen = watchActiveSubscription(ref) != null;
    final sentences = splitSentences(entry.correctedText);
    String sentenceOf(CorrectionItem item) => sentences.firstWhere(
      (sentence) => sentence.contains(item.corrected),
      orElse: () => entry.correctedText,
    );

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
              _Versions(entry: entry),
              if (items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                SectionTitle(l10n.correctionToRemember),
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    // Premium : chaque faute est classée par catégorie (US-12).
                    child: CorrectionItemCard(
                      item: item,
                      showsCategory: isAdvanced,
                      listen: canListen
                          ? (text: sentenceOf(item), language: entry.language)
                          : null,
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.lg),
              RewriteSection(entry: entry),
            ],
          ),
        ),
        // Mots à réviser et fin de lecture, toujours à portée de main.
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (entry.vocabulary.isNotEmpty) ...[
                _VocabularyChips(words: entry.vocabulary),
                const SizedBox(height: AppSpacing.md),
              ],
              FilledButton(
                onPressed: () => context.pop(),
                child: Text(l10n.correctionDone),
              ),
            ],
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
  const _Versions({required this.entry});

  final JournalEntry entry;

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
        _PillToggle(
          labels: (l10n.correctionYourVersion, l10n.correctionCorrectedVersion),
          selectsSecond: _showsCorrected,
          onChanged: (selectsSecond) =>
              setState(() => _showsCorrected = selectsSecond),
        ),
        const SizedBox(height: AppSpacing.md),
        SoftCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: _showsCorrected
              ? HighlightedText(
                  text: entry.correctedText,
                  fragments: [for (final item in items) item.corrected],
                  highlightStyle: TextStyle(
                    color: colors.fix,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: colors.fix,
                    decorationThickness: 2,
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
      ],
    );
  }
}

/// Deux choix côte à côte dans une pilule blanche ; le choix actif est
/// teinté de vert.
class _PillToggle extends StatelessWidget {
  const _PillToggle({
    required this.labels,
    required this.selectsSecond,
    required this.onChanged,
  });

  static const _segmentHeight = 40.0;
  static const _inset = 6.0;

  final (String, String) labels;
  final bool selectsSecond;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget segment(String label, {required bool second}) {
      final isSelected = second == selectsSecond;
      return Expanded(
        child: Semantics(
          button: true,
          selected: isSelected,
          // Le toucher couvre aussi la marge autour de la pastille.
          child: InkWell(
            onTap: () => onChanged(second),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                second ? _inset / 2 : _inset,
                _inset,
                second ? _inset : _inset / 2,
                _inset,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  color: isSelected ? scheme.primaryContainer : null,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Container(
                  constraints: const BoxConstraints(minHeight: _segmentHeight),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SoftCard(
      radius: AppRadius.card,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          segment(labels.$1, second: false),
          segment(labels.$2, second: true),
        ],
      ),
    );
  }
}

/// Mots relevés dans le journal, avec leur traduction, sur une ligne.
class _VocabularyChips extends StatelessWidget {
  const _VocabularyChips({required this.words});

  final List<VocabularyItem> words;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSecondaryContainer,
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: AppSpacing.sm,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      word.term,
                      style: style?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    ExcludeSemantics(child: Text(' · ', style: style)),
                    Text(word.translation, style: style),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
