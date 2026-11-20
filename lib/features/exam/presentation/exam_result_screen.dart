import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../journal/presentation/correction_item_card.dart';
import '../../journal/presentation/highlighted_text.dart';
import '../../languages/presentation/language_labels.dart';
import '../../reports/domain/content_report_repository.dart';
import '../../reports/presentation/report_content_button.dart';
import '../application/exam_providers.dart';
import '../domain/exam.dart';

/// Résultat d'une simulation : note, critères, copie corrigée et plan de
/// révision (US-20).
class ExamResultScreen extends ConsumerWidget {
  const ExamResultScreen({required this.examId, super.key});

  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: SoftAppBar(
        title: l10n.examTitle,
        actions: [
          ReportContentButton(
            content: ReportedContent.exam,
            targetId: examId,
            style: roundButtonStyle(context),
          ),
        ],
      ),
      body: SafeArea(
        child: AsyncView(
          value: ref.watch(examsProvider),
          onRetry: () => ref.invalidate(examsProvider),
          builder: (exams) {
            final exam = exams.where((exam) => exam.id == examId).firstOrNull;
            final result = exam?.result;
            return exam == null || result == null
                ? const SizedBox.shrink()
                : _Result(exam: exam, result: result);
          },
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.exam, required this.result});

  static const _heroSize = 56.0;

  final Exam exam;
  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColors>()!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        HeroCard(
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.examResultSubtitle(
                      languageName(l10n, exam.language),
                      exam.level.code,
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    l10n.examScore(result.score),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: _heroSize,
                    ),
                  ),
                  Text(
                    l10n.examLevelEstimate(result.levelEstimate),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(result.summary),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionTitle(l10n.examCriteriaTitle),
        for (final criterion in result.criteria) _CriterionRow(criterion),
        const SizedBox(height: AppSpacing.xl),
        SectionTitle(l10n.correctionYourVersion),
        SoftCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: HighlightedText(
            text: exam.answer ?? '',
            fragments: [for (final item in result.items) item.original],
            highlightStyle: TextStyle(
              color: colors.mistake,
              decoration: TextDecoration.lineThrough,
              decorationColor: colors.mistake,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionTitle(l10n.examCorrectedTitle),
        SoftCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: HighlightedText(
            text: result.correctedText,
            fragments: [for (final item in result.items) item.corrected],
            highlightStyle: TextStyle(
              color: colors.fix,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: colors.fix,
            ),
          ),
        ),
        for (final item in result.items)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: CorrectionItemCard(item: item, showsCategory: true),
          ),
        const SizedBox(height: AppSpacing.xl),
        SectionTitle(l10n.examPlanTitle),
        for (final (index, step) in result.revisionPlan.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SoftCard(
              radius: AppRadius.tile,
              elevated: false,
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                leading: CircleAvatar(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.onAccent,
                  child: Text('${index + 1}'),
                ),
                title: Text(step.title),
                subtitle: Text(step.details),
              ),
            ),
          ),
      ],
    );
  }
}

/// Un critère : son nom, une jauge sur 5 et le commentaire de l'examinateur.
class _CriterionRow extends StatelessWidget {
  const _CriterionRow(this.criterion);

  static const _maxScore = 5;

  final CriterionScore criterion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = switch (criterion.criterion) {
      ExamCriterion.task => l10n.criterionTask,
      ExamCriterion.coherence => l10n.criterionCoherence,
      ExamCriterion.vocabulary => l10n.criterionVocabulary,
      ExamCriterion.grammar => l10n.criterionGrammar,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SoftCard(
        radius: AppRadius.tile,
        elevated: false,
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(name, style: theme.textTheme.titleSmall),
                  ),
                  Text(
                    l10n.examCriterionScore(criterion.score),
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SoftProgressBar(value: criterion.score / _maxScore),
              const SizedBox(height: AppSpacing.sm),
              Text(
                criterion.comment,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
