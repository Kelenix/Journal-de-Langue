import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/session_gate.dart';
import '../../auth/application/auth_providers.dart';
import '../../languages/application/language_providers.dart';

/// Affiché pendant le chargement du compte, ou si ce chargement a échoué.
class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasFailed = ref.watch(sessionGateProvider) == SessionGate.failed;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: hasFailed
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.startupError, textAlign: TextAlign.center),
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
              : CircularProgressIndicator(semanticsLabel: l10n.appTitle),
        ),
      ),
    );
  }
}
