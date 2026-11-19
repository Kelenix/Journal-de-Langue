import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../../shared/widgets/error_message.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../languages/domain/learning_language.dart';
import '../../stats/presentation/streak_badge.dart';
import '../../voice/presentation/voice_buttons.dart';
import '../application/journal_providers.dart';
import '../domain/journal_draft_store.dart';
import '../domain/journal_entry.dart';
import '../domain/sentences.dart';

/// Rédaction et envoi du journal du jour. Le brouillon est conservé sur
/// l'appareil : rien n'est perdu hors ligne ou si l'app est fermée.
class JournalEditor extends ConsumerStatefulWidget {
  const JournalEditor({
    required this.userId,
    required this.language,
    required this.allowance,
    super.key,
  });

  final String userId;
  final LearningLanguage language;
  final JournalAllowance allowance;

  @override
  ConsumerState<JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends ConsumerState<JournalEditor> {
  static const _draftSaveDelay = Duration(milliseconds: 600);
  static const _minEditorLines = 6;

  final _text = TextEditingController();
  // Gardé hors de `ref` : il sert encore pendant la fermeture de l'écran.
  late final JournalDraftStore _drafts = ref.read(journalDraftStoreProvider);
  Timer? _draftSaveTimer;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    _text.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (_draftSaveTimer?.isActive ?? false) {
      _draftSaveTimer!.cancel();
      _saveDraft();
    }
    _text.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final draft = await _drafts.load(widget.userId, widget.language);
    // Ne pas écraser ce que l'utilisateur a déjà commencé à écrire.
    if (mounted && _text.text.isEmpty) _text.text = draft;
  }

  void _onTextChanged() {
    setState(() {}); // compteur de phrases
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(_draftSaveDelay, _saveDraft);
  }

  Future<void> _saveDraft() =>
      _drafts.save(widget.userId, widget.language, _text.text);

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final entry = await ref
        .read(journalSubmissionControllerProvider.notifier)
        .submit(
          text: _text.text.trim(),
          language: widget.language,
          uiLocale: Localizations.localeOf(context).languageCode,
        );
    if (entry == null || !mounted) return;

    _text.clear();
    await context.push(AppRoutes.correctionOf(entry.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final submission = ref.watch(journalSubmissionControllerProvider);
    final submissionError = submission.error;

    final maxSentences = widget.allowance.maxSentences;
    final sentenceCount = countSentences(_text.text);
    final isOverLimit = sentenceCount > maxSentences;
    final canSubmit = sentenceCount > 0 && !isOverLimit;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(l10n.journalGreeting, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.journalHeadline,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const StreakBadge(),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.journalIntro,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.journalCardTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    // Dictée réservée à Premium (US-15).
                    if (widget.allowance.plan != null)
                      DictationButton(
                        controller: _text,
                        language: widget.language,
                        maxCharacters: widget.allowance.maxCharacters,
                        enabled: !submission.isLoading,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _text,
                  enabled: !submission.isLoading,
                  minLines: _minEditorLines,
                  maxLines: null,
                  maxLength: widget.allowance.maxCharacters,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: l10n.journalEmpty,
                    // Sur une carte blanche, le champ reprend le fond ivoire.
                    fillColor: theme.colorScheme.surface,
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                _SentenceProgress(count: sentenceCount, max: maxSentences),
                if (submissionError != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  ErrorMessage(failureMessage(l10n, submissionError)),
                ],
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: l10n.journalSubmit,
                  isLoading: submission.isLoading,
                  onPressed: canSubmit ? _submit : null,
                ),
                if (submission.isLoading) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.journalSubmitting,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Nombre de phrases écrites par rapport à la limite de l'offre.
class _SentenceProgress extends StatelessWidget {
  const _SentenceProgress({required this.count, required this.max});

  static const _barHeight = 6.0;

  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isOverLimit = count > max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Le texte ci-dessous porte l'information pour les lecteurs d'écran.
        ExcludeSemantics(
          child: LinearProgressIndicator(
            value: (count / max).clamp(0, 1).toDouble(),
            minHeight: _barHeight,
            borderRadius: BorderRadius.circular(_barHeight),
            backgroundColor: theme.colorScheme.outlineVariant,
            color: isOverLimit
                ? theme.colorScheme.error
                : theme.extension<AppColors>()!.accent,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isOverLimit
              ? l10n.journalTooManySentences(max)
              : l10n.journalSentenceCount(count, max),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isOverLimit
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
