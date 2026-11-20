import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/session_gate.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../auth/application/auth_providers.dart';
import '../../languages/application/language_providers.dart';

/// Affiché pendant le chargement du compte, ou si ce chargement a échoué :
/// l'aplat vert de la marque prolonge l'écran de lancement.
class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasFailed = ref.watch(sessionGateProvider) == SessionGate.failed;

    return Scaffold(
      body: HeroCard(
        borderRadius: BorderRadius.zero,
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: Center(
            child: Builder(
              builder: (context) => hasFailed
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.startupError,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton(
                            onPressed: () {
                              ref.invalidate(currentUserIdProvider);
                              ref.invalidate(activeLanguagesProvider);
                            },
                            child: Text(l10n.actionRetry),
                          ),
                        ],
                      ),
                    )
                  : CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onSurface,
                      semanticsLabel: l10n.appTitle,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
