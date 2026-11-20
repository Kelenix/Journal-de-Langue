import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../ads/domain/ad_status.dart';
import '../../ads/presentation/ad_widgets.dart';
import '../../billing/application/billing_providers.dart';
import '../../journal/application/journal_providers.dart';
import '../../journal/presentation/category_labels.dart';
import '../../languages/application/language_providers.dart';
import '../../reports/domain/content_report_repository.dart';
import '../../reports/presentation/report_content_button.dart';
import '../application/exercise_providers.dart';
import '../domain/exercise.dart';

/// Séance d'exercices à choix multiple (US-14).
class ExerciseScreen extends ConsumerWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(activeLanguagesProvider).value?.firstOrNull;

    return Scaffold(
      appBar: SoftAppBar(title: l10n.exercisesTitle),
      body: SafeArea(
        // Sans langue, la navigation quitte cet écran.
        child: language == null
            ? const SizedBox.shrink()
            : _Session(
                sessionKey: (
                  language: language,
                  uiLocale: Localizations.localeOf(context).languageCode,
                ),
              ),
      ),
    );
  }
}

class _Session extends ConsumerWidget {
  const _Session({required this.sessionKey});

  final ExerciseSessionKey sessionKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = exerciseSessionProvider(sessionKey);
    return AsyncView(
      // Pendant qu'un nouveau lot se prépare, l'ancien ne reste pas affiché.
      value: ref.watch(provider).unwrapPrevious(),
      onRetry: () => ref.invalidate(provider),
      builder: (session) => switch (session.batch) {
        ExerciseLimitReached() => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: _DailyLimit(),
          ),
        ),
        final AvailableExercises batch
            when session.index < batch.exercises.length =>
          _Question(
            // Une nouvelle question repart sans réponse en attente.
            key: ValueKey(batch.exercises[session.index].id),
            batch: batch,
            session: session,
            controller: ref.read(provider.notifier),
          ),
        final AvailableExercises batch => _Result(
          session: session,
          total: batch.exercises.length,
          left: session.answers.lastOrNull?.feedback.left ?? batch.left,
          onContinue: () => ref.invalidate(provider),
        ),
      },
    );
  }
}

class _Question extends StatefulWidget {
  const _Question({
    required this.batch,
    required this.session,
    required this.controller,
    super.key,
  });

  final AvailableExercises batch;
  final ExerciseSession session;
  final ExerciseSessionController controller;

  @override
  State<_Question> createState() => _QuestionState();
}

class _QuestionState extends State<_Question> {
  bool _isAnswering = false;

  Future<void> _answer(Exercise exercise, int choice) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isAnswering = true);
    try {
      await widget.controller.answer(exercise, choice);
    } on Failure catch (failure) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, failure))),
      );
    } finally {
      if (mounted) setState(() => _isAnswering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final batch = widget.batch;
    final session = widget.session;
    final exercise = batch.exercises[session.index];
    final answer = session.currentAnswer;
    final isLast = session.index == batch.exercises.length - 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.exerciseProgress(
                  session.index + 1,
                  batch.exercises.length,
                ),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ReportContentButton(
              content: ReportedContent.exercise,
              targetId: exercise.id,
              style: roundButtonStyle(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SoftProgressBar(value: (session.index + 1) / batch.exercises.length),
        const SizedBox(height: AppSpacing.lg),
        SoftCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  Tag(errorCategoryName(l10n, batch.category)),
                  if (batch.isPersonalized)
                    Tag(l10n.exercisesPersonalized, warm: true),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                header: true,
                child: Text(
                  exercise.question,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final (choice, option) in exercise.options.indexed)
          _Option(
            label: option,
            mark: switch (answer) {
              null => null,
              (choice: _, :final feedback)
                  when feedback.answerIndex == choice =>
                _OptionMark.rightAnswer,
              (choice: final chosen, feedback: _) when chosen == choice =>
                _OptionMark.wrongChoice,
              _ => null,
            },
            onSelected: answer == null && !_isAnswering
                ? () => _answer(exercise, choice)
                : null,
          ),
        if (answer != null) ...[
          const SizedBox(height: AppSpacing.md),
          SoftCard(
            color: answer.feedback.isCorrect
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.secondaryContainer,
            elevated: false,
            radius: AppRadius.tile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(
                    answer.feedback.isCorrect
                        ? l10n.exerciseCorrect
                        : l10n.exerciseIncorrect,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(answer.feedback.explanation),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: widget.controller.next,
            child: Text(isLast ? l10n.exerciseSeeResult : l10n.exerciseNext),
          ),
        ],
      ],
    );
  }
}

enum _OptionMark { rightAnswer, wrongChoice }

/// Une réponse possible. Une fois l'exercice corrigé, la bonne réponse et le
/// mauvais choix portent une icône : jamais la couleur seule.
class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.mark,
    required this.onSelected,
  });

  final String label;
  final _OptionMark? mark;
  final VoidCallback? onSelected;

  static const _mistakeTint = 0.1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SoftCard(
        radius: AppRadius.tile,
        elevated: false,
        padding: EdgeInsets.zero,
        color: switch (mark) {
          _OptionMark.rightAnswer => theme.colorScheme.primaryContainer,
          _OptionMark.wrongChoice => colors.mistake.withValues(
            alpha: _mistakeTint,
          ),
          null => null,
        },
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          title: Text(label),
          trailing: switch (mark) {
            _OptionMark.rightAnswer => Icon(
              Icons.check_circle,
              color: colors.fix,
              semanticLabel: l10n.exerciseRightAnswer,
            ),
            _OptionMark.wrongChoice => Icon(
              Icons.cancel,
              color: colors.mistake,
              semanticLabel: l10n.exerciseYourAnswer,
            ),
            null => null,
          },
          onTap: onSelected,
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.session,
    required this.total,
    required this.left,
    required this.onContinue,
  });

  static const _badgeRadius = 28.0;

  final ExerciseSession session;
  final int total;

  /// Exercices encore permis aujourd'hui.
  final int left;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        HeroCard(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final colors = theme.extension<AppColors>()!;
              return Column(
                children: [
                  ExcludeSemantics(
                    child: CircleAvatar(
                      radius: _badgeRadius,
                      backgroundColor: colors.accent,
                      foregroundColor: colors.onAccent,
                      child: const Icon(Icons.emoji_events_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.exerciseScore(session.correctAnswers, total),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.correctionEncouragement,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (left > 0)
          FilledButton(onPressed: onContinue, child: Text(l10n.actionContinue))
        else
          const _DailyLimit(),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => context.pop(),
          child: Text(l10n.exercisesDone),
        ),
      ],
    );
  }
}

/// La limite d'exercices du jour est atteinte.
class _DailyLimit extends ConsumerWidget {
  const _DailyLimit();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isPremium = watchActiveSubscription(ref) != null;

    return SoftCard(
      color: Theme.of(context).colorScheme.secondaryContainer,
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: IconBadge(Icons.bedtime_outlined, accent: true)),
          const SizedBox(height: AppSpacing.md),
          Text(
            isPremium ? l10n.exercisesLimitPremium : l10n.exercisesLimitFree,
            textAlign: TextAlign.center,
          ),
          // Jamais d'offre payante avant une première correction
          // (INTAKE §6).
          if (!isPremium && watchHasCorrectedJournal(ref)) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => context.push(AppRoutes.paywall),
              child: Text(l10n.paywallDiscover),
            ),
          ],
          RewardedAdButton(
            kind: AdRewardKind.exercises,
            onReload: () => ref.invalidate(exerciseSessionProvider),
          ),
        ],
      ),
    );
  }
}
