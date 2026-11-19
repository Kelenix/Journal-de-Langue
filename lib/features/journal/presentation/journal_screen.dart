import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/widgets/async_view.dart';
import '../../auth/application/auth_providers.dart';
import '../../languages/application/language_providers.dart';
import '../../languages/presentation/language_labels.dart';
import '../application/journal_providers.dart';
import '../domain/journal_entry.dart';
import 'journal_editor.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final userId = ref.watch(currentUserIdProvider).value;
    final language = ref.watch(activeLanguagesProvider).value?.firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.journalTitle),
        actions: [
          if (language != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Chip(label: Text(languageName(l10n, language))),
            ),
        ],
      ),
      body: SafeArea(
        // Sans session ni langue, la navigation quitte cet écran.
        child: userId == null || language == null
            ? const SizedBox.shrink()
            : AsyncView(
                value: ref.watch(journalDayProvider),
                onRetry: () => ref.invalidate(journalDayProvider),
                builder: (day) => day.allowance.correctionsLeft > 0
                    ? JournalEditor(
                        // Un brouillon par compte et par langue.
                        key: ValueKey((userId, language)),
                        userId: userId,
                        language: language,
                        allowance: day.allowance,
                      )
                    : _DailyLimitReached(entry: day.entry),
              ),
      ),
    );
  }
}

/// La correction du jour est utilisée : accès à la correction et rappel.
class _DailyLimitReached extends StatelessWidget {
  const _DailyLimitReached({required this.entry});

  static const _badgeRadius = 28.0;

  final JournalEntry? entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final entry = this.entry;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (entry != null)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  ExcludeSemantics(
                    child: CircleAvatar(
                      radius: _badgeRadius,
                      backgroundColor: colors.accent,
                      foregroundColor: colors.onAccent,
                      child: const Icon(Icons.check),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.journalCorrectedTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.journalCorrectedBody, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: () =>
                        context.push(AppRoutes.correctionOf(entry.id)),
                    child: Text(l10n.journalViewCorrection),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.journalDailyLimitReached,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
