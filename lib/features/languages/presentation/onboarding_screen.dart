import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/form_page.dart';
import '../../auth/application/auth_providers.dart';
import 'language_choice_list.dart';

/// Première étape après l'inscription : choisir la langue à apprendre.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return FormPage(
      title: l10n.onboardingTitle,
      children: [
        // Une fois la langue activée, la navigation suit l'état de session.
        const LanguageChoiceList(),
        const SizedBox(height: AppSpacing.xl),
        TextButton(
          onPressed: () =>
              ref.read(accountControllerProvider.notifier).signOut(),
          child: Text(l10n.profileSignOut),
        ),
      ],
    );
  }
}
