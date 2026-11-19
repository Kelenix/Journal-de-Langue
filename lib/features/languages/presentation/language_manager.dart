import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../../shared/widgets/error_message.dart';
import '../application/language_providers.dart';
import '../domain/learning_language.dart';
import 'language_labels.dart';

/// Langues d'un abonné : en ajouter, choisir celle du journal, en retirer
/// (US-04). Le serveur applique la limite de l'offre.
class LanguageManager extends ConsumerWidget {
  const LanguageManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languages = ref.watch(activeLanguagesProvider).value ?? const [];
    final action = ref.watch(languageSelectionControllerProvider);
    final controller = ref.read(languageSelectionControllerProvider.notifier);
    final current = languages.firstOrNull;
    final error = action.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final language in LearningLanguage.values)
          Card(
            child: ListTile(
              leading: Icon(
                languages.contains(language)
                    ? Icons.check_circle
                    : Icons.add_circle_outline,
              ),
              title: Text(languageName(l10n, language)),
              subtitle: Text(
                language == current
                    ? l10n.languageCurrent
                    : languages.contains(language)
                    ? l10n.languageMakeCurrent
                    : l10n.languageAdd,
              ),
              selected: language == current,
              enabled: !action.isLoading,
              onTap: language == current
                  ? null
                  : () => controller.select(language),
              // Il reste toujours au moins une langue.
              trailing: languages.contains(language) && languages.length > 1
                  ? IconButton(
                      tooltip: l10n.languageRemove,
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: action.isLoading
                          ? null
                          : () => controller.remove(language),
                    )
                  : null,
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
