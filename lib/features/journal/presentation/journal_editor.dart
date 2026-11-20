import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/error_message.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../ads/application/ads_providers.dart';
import '../../ads/presentation/ad_widgets.dart';
import '../../languages/domain/learning_language.dart';
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

class _JournalEditorState extends ConsumerState<JournalEditor>
    with WidgetsBindingObserver {
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
    // Pas de publicité clavier ouvert (INTAKE §5.2) : l'écran suit le clavier.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    if (_draftSaveTimer?.isActive ?? false) {
      _draftSaveTimer!.cancel();
      _saveDraft();
    }
    _text.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
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
    // Gardé avant la navigation : l'éditeur peut disparaître entre-temps.
    final ads = ref.read(adsControllerProvider.notifier);
    await context.push(AppRoutes.correctionOf(entry.id));
    // Interstitiel à la sortie de la correction, jamais pendant sa lecture.
    await ads.afterCorrection();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final submission = ref.watch(journalSubmissionControllerProvider);
    final submissionError = submission.error;
    final allowance = widget.allowance;

    final maxSentences = allowance.maxSentences;
    final sentenceCount = countSentences(_text.text);
    final isOverLimit = sentenceCount > maxSentences;
    final canSubmit = sentenceCount > 0 && !isOverLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.journalCardTitle,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.journalIntro,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dictée réservée à Premium (US-15).
                  if (allowance.plan != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    DictationButton(
                      controller: _text,
                      language: widget.language,
                      maxCharacters: allowance.maxCharacters,
                      enabled: !submission.isLoading,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _text,
                enabled: !submission.isLoading,
                minLines: _minEditorLines,
                maxLines: null,
                maxLength: allowance.maxCharacters,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(hintText: l10n.journalEmpty),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              _SentenceProgress(count: sentenceCount, max: maxSentences),
              if (allowance.correctionsLeft == 0) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  allowance.credits > 0
                      ? l10n.journalUsesCredit(allowance.credits)
                      : l10n.journalUsesReward,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (submissionError != null) ...[
                const SizedBox(height: AppSpacing.lg),
                ErrorMessage(failureMessage(l10n, submissionError)),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: l10n.journalSubmit,
                isLoading: submission.isLoading,
                onPressed: canSubmit ? _submit : null,
              ),
              if (submission.isLoading || allowance.correctionsLeft > 0) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  submission.isLoading
                      ? l10n.journalSubmitting
                      : l10n.journalCorrectionsLeft(allowance.correctionsLeft),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ],
          ),
        ),
        // Pas de publicité pendant la saisie : clavier ouvert ou texte en cours.
        if (_text.text.isEmpty && View.of(context).viewInsets.bottom == 0)
          const AdBanner(),
      ],
    );
  }
}

/// Nombre de phrases écrites par rapport à la limite de l'offre.
class _SentenceProgress extends StatelessWidget {
  const _SentenceProgress({required this.count, required this.max});

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
        SoftProgressBar(
          value: count / max,
          color: isOverLimit ? theme.colorScheme.error : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isOverLimit
              ? l10n.journalTooManySentences(max)
              : l10n.journalSentenceCount(count, max),
          style: theme.textTheme.bodySmall?.copyWith(
            color: isOverLimit
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
