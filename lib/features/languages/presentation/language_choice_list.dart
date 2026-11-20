import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../../shared/widgets/error_message.dart';
import '../application/language_providers.dart';
import '../domain/learning_language.dart';
import 'language_labels.dart';

/// Les quatre langues proposées ; un appui active la langue choisie.
class LanguageChoiceList extends ConsumerWidget {
  const LanguageChoiceList({this.selected, this.onActivated, super.key});

  /// Langue actuellement active, mise en évidence.
  final LearningLanguage? selected;

  /// Appelé une fois la langue activée côté serveur.
  final VoidCallback? onActivated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final action = ref.watch(languageSelectionControllerProvider);
    final error = action.error;

    Future<void> select(LearningLanguage language) async {
      final isActivated = await ref
          .read(languageSelectionControllerProvider.notifier)
          .select(language);
      // La feuille a pu être refermée pendant l'activation.
      if (isActivated && context.mounted) onActivated?.call();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final language in LearningLanguage.values)
          Card(
            child: ListTile(
              title: Text(languageName(l10n, language)),
              selected: language == selected,
              trailing: language == selected ? const Icon(Icons.check) : null,
              enabled: !action.isLoading,
              onTap: () => select(language),
            ),
          ),
        if (action.isLoading)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.lg),
            child: LinearProgressIndicator(),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: ErrorMessage(failureMessage(l10n, error)),
          ),
      ],
    );
  }
}
