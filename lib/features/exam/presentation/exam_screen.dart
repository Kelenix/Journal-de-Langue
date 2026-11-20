import 'dart:async';

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
import '../../../shared/widgets/error_message.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../billing/application/billing_providers.dart';
import '../../journal/application/journal_providers.dart';
import '../../languages/application/language_providers.dart';
import '../../languages/presentation/language_labels.dart';
import '../application/exam_providers.dart';
import '../domain/exam.dart';
import '../domain/exam_repository.dart';

/// Simulation d'examen du Pack Examinateur (US-20) : choix du niveau, sujet,
/// rédaction, puis résultats.
class ExamScreen extends ConsumerWidget {
  const ExamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: SoftAppBar(title: l10n.examTitle),
      body: SafeArea(
        child: AsyncView(
          value: ref.watch(examsProvider),
          onRetry: () => ref.invalidate(examsProvider),
          builder: (exams) {
            final open = exams
                .where((exam) => exam.status != ExamStatus.graded)
                .firstOrNull;
            return switch (open) {
              null => _ExamHome(graded: exams),
              // Copie remise, notation en cours : plus rien à modifier.
              Exam(status: ExamStatus.grading) => const _ExamGrading(),
              _ => _ExamWriting(key: ValueKey(open.id), exam: open),
            };
          },
        ),
      ),
    );
  }
}

/// Lancer une simulation, ou obtenir un Pack Examinateur ; puis les résultats
/// passés.
class _ExamHome extends ConsumerStatefulWidget {
  const _ExamHome({required this.graded});

  final List<Exam> graded;

  @override
  ConsumerState<_ExamHome> createState() => _ExamHomeState();
}

class _ExamHomeState extends ConsumerState<_ExamHome> {
  ExamLevel _level = ExamLevel.b1;

  Future<void> _start() async {
    final language = ref.read(activeLanguagesProvider).value?.firstOrNull;
    if (language == null) return;
    await ref
        .read(examControllerProvider.notifier)
        .start(
          language: language,
          level: _level,
          uiLocale: Localizations.localeOf(context).languageCode,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final wallet = ref.watch(walletProvider);
    final credits = wallet.value?.examCredits ?? 0;
    final action = ref.watch(examControllerProvider);
    final error = action.error;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const IconBadge(Icons.school_outlined, warm: true),
        const SizedBox(height: AppSpacing.lg),
        // Portefeuille pas encore lu : ni « aucun pack » ni « acheter un pack »
        // à quelqu'un qui en a peut-être un.
        if (!wallet.hasValue || wallet.hasError)
          AsyncView(
            value: wallet,
            onRetry: () => ref.invalidate(walletProvider),
            builder: (_) => const SizedBox.shrink(),
          )
        else if (credits > 0) ...[
          Text(
            l10n.examCreditsLeft(credits),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.examChooseLevel),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<ExamLevel>(
            segments: [
              for (final level in ExamLevel.values)
                ButtonSegment(value: level, label: Text(level.code)),
            ],
            selected: {_level},
            showSelectedIcon: false,
            onSelectionChanged: action.isLoading
                ? null
                : (selection) => setState(() => _level = selection.single),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: l10n.examStart,
            isLoading: action.isLoading,
            onPressed: _start,
          ),
          if (action.isLoading) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.examStarting, textAlign: TextAlign.center),
          ],
        ] else ...[
          Text(l10n.examNoCredit),
          // Rappel en contexte : seulement après une première correction
          // (ADR-040).
          if (watchHasCorrectedJournal(ref)) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => context.push(AppRoutes.shop),
              child: Text(l10n.examBuyPack),
            ),
          ],
        ],
        if (error != null) ...[
          const SizedBox(height: AppSpacing.md),
          ErrorMessage(failureMessage(l10n, error)),
        ],
      ],
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        SoftCard(padding: const EdgeInsets.all(AppSpacing.xl), child: content),
        if (widget.graded.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          SectionTitle(l10n.examResultsTitle),
          for (final exam in widget.graded) _ResultTile(exam: exam),
        ],
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.exam});

  final Exam exam;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final score = exam.result?.score;

    return Padding(
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
          title: Text(
            MaterialLocalizations.of(
              context,
            ).formatMediumDate((exam.gradedAt ?? exam.createdAt).toLocal()),
          ),
          subtitle: Text(
            l10n.examResultSubtitle(
              languageName(l10n, exam.language),
              exam.level.code,
            ),
          ),
          trailing: score == null
              ? null
              : Text(l10n.examScore(score), style: theme.textTheme.titleMedium),
          onTap: () => context.push(AppRoutes.examResultOf(exam.id)),
        ),
      ),
    );
  }
}

/// Le sujet et la rédaction. Le brouillon est enregistré au fil de la saisie :
/// une simulation interrompue le retrouve.
class _ExamWriting extends ConsumerStatefulWidget {
  const _ExamWriting({required this.exam, super.key});

  final Exam exam;

  @override
  ConsumerState<_ExamWriting> createState() => _ExamWritingState();
}

class _ExamWritingState extends ConsumerState<_ExamWriting> {
  static const _draftSaveDelay = Duration(seconds: 2);
  static const _maxCharacters = 6000;
  static const _minLines = 10;
  static final _word = RegExp(r'\S+');

  late final _text = TextEditingController(text: widget.exam.answer ?? '');
  // Lu dès le départ, hors de `ref` : il sert encore pendant la fermeture de
  // l'écran, où `ref` n'est plus utilisable.
  late final ExamRepository _exams;
  late String _lastText = _text.text;
  Timer? _draftSaveTimer;
  bool _isDraftUnsaved = false;

  @override
  void initState() {
    super.initState();
    _exams = ref.read(examRepositoryProvider);
    _text.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    // Le dernier texte saisi part avec la fermeture de l'écran.
    if (_draftSaveTimer?.isActive ?? false) {
      _draftSaveTimer!.cancel();
      unawaited(
        _exams
            .saveDraft(examId: widget.exam.id, answer: _text.text)
            .catchError((Object _) {}),
      );
    }
    _text.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Le curseur qui bouge ne change pas le texte : rien à enregistrer.
    if (_text.text == _lastText) return;
    _lastText = _text.text;
    setState(() {}); // compteur de mots
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(_draftSaveDelay, _saveDraft);
  }

  Future<void> _saveDraft() async {
    var isSaved = true;
    try {
      await _exams.saveDraft(examId: widget.exam.id, answer: _text.text);
    } on Failure {
      // Hors ligne : le texte reste à l'écran et l'utilisateur est prévenu.
      isSaved = false;
    }
    if (mounted) setState(() => _isDraftUnsaved = !isSaved);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _draftSaveTimer?.cancel();
    final router = GoRouter.of(context);
    final isGraded = await ref
        .read(examControllerProvider.notifier)
        .submit(examId: widget.exam.id, answer: _text.text.trim());
    // Écran quitté pendant la notation : pas de résultat ouvert par-dessus.
    if (isGraded && mounted) {
      await router.push(AppRoutes.examResultOf(widget.exam.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final prompt = widget.exam.prompt;
    final action = ref.watch(examControllerProvider);
    final error = action.error;
    final wordCount = _word.allMatches(_text.text).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        if (prompt != null)
          SoftCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tag(
                  l10n.examResultSubtitle(
                    languageName(l10n, widget.exam.language),
                    widget.exam.level.code,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  header: true,
                  child: Text(prompt.title, style: theme.textTheme.titleLarge),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(prompt.task),
                const SizedBox(height: AppSpacing.md),
                Tag(
                  l10n.examWordTarget(prompt.minWords, prompt.maxWords),
                  warm: true,
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _text,
          enabled: !action.isLoading,
          minLines: _minLines,
          maxLines: null,
          maxLength: _maxCharacters,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l10n.examAnswerHint),
        ),
        Text(
          l10n.examWordCount(wordCount),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.md),
          ErrorMessage(failureMessage(l10n, error)),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: l10n.examSubmit,
          isLoading: action.isLoading,
          onPressed: wordCount == 0 ? null : _submit,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          action.isLoading
              ? l10n.examGrading
              : _isDraftUnsaved
              ? l10n.examDraftNotSaved
              : l10n.examResumeNote,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: _isDraftUnsaved && !action.isLoading
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Copie remise, en cours de notation par le serveur.
class _ExamGrading extends ConsumerWidget {
  const _ExamGrading();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        SoftCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const IconBadge(Icons.hourglass_top_outlined, warm: true),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.examGrading),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: () => ref.invalidate(examsProvider),
                child: Text(l10n.actionRefresh),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
