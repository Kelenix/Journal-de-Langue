import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/external_links.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../auth/application/auth_providers.dart';
import '../../billing/application/billing_providers.dart';
import '../../billing/domain/subscription.dart';
import '../../billing/presentation/offer_labels.dart';
import '../../journal/application/journal_providers.dart';
import '../../languages/application/language_providers.dart';
import '../../languages/domain/learning_language.dart';
import '../../languages/presentation/language_choice_list.dart';
import '../../languages/presentation/language_labels.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final activeLanguage = ref
        .watch(activeLanguagesProvider)
        .value
        ?.firstOrNull;
    final accountAction = ref.watch(accountControllerProvider);

    ref.listen(accountControllerProvider, (_, next) {
      final error = next.error;
      if (error == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage(l10n, error))));
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProfile)),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.translate),
              title: Text(l10n.profileLanguage),
              subtitle: activeLanguage == null
                  ? null
                  : Text(languageName(l10n, activeLanguage)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguagePicker(context, activeLanguage),
            ),
            const _PlanSection(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l10n.profileSignOut),
              enabled: !accountAction.isLoading,
              onTap: () =>
                  ref.read(accountControllerProvider.notifier).signOut(),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(
                l10n.profileDeleteAccount,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              enabled: !accountAction.isLoading,
              onTap: () => _confirmAccountDeletion(context, ref),
            ),
            const Divider(),
            AboutListTile(
              icon: const Icon(Icons.info_outline),
              applicationName: l10n.appTitle,
              aboutBoxChildren: [Text(l10n.appTagline)],
              child: Text(l10n.aboutApp),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    LearningLanguage? activeLanguage,
  ) {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.profileChangeLanguageNote),
              const SizedBox(height: AppSpacing.lg),
              LanguageChoiceList(
                selected: activeLanguage,
                onActivated: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Deux confirmations successives avant une suppression irréversible.
  Future<void> _confirmAccountDeletion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final hasAcceptedLoss = await _confirm(
      context,
      title: l10n.deleteAccountTitle,
      body: l10n.deleteAccountBody,
      confirmLabel: l10n.actionContinue,
    );
    if (!hasAcceptedLoss || !context.mounted) return;

    final hasConfirmed = await _confirm(
      context,
      title: l10n.deleteAccountFinalTitle,
      body: l10n.deleteAccountFinalBody,
      confirmLabel: l10n.deleteAccountConfirm,
    );
    if (!hasConfirmed) return;

    // Lus avant l'attente : la suppression ferme cet écran.
    final drafts = ref.read(journalDraftStoreProvider);
    final isDeleted = await ref
        .read(accountControllerProvider.notifier)
        .deleteAccount();
    // Les brouillons restés sur l'appareil font partie des données du compte.
    if (isDeleted) await drafts.clearAll();
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final l10n = AppLocalizations.of(context);
    final isConfirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return isConfirmed ?? false;
  }
}

/// Offre de l'utilisateur, restauration des achats et gestion de l'abonnement.
class _PlanSection extends ConsumerWidget {
  const _PlanSection();

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final isRestored = await ref
        .read(paywallControllerProvider.notifier)
        .restore();
    final error = ref.read(paywallControllerProvider).error;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isRestored
              ? l10n.paywallWelcome
              : failureMessage(l10n, error ?? const UnexpectedFailure()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final subscription = watchActiveSubscription(ref);
    final isRestoring = ref.watch(paywallControllerProvider).isLoading;
    // Les offres payantes ne sont jamais proposées avant une première
    // correction (INTAKE §6).
    final canDiscoverPremium =
        subscription == null && watchHasCorrectedJournal(ref);

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.workspace_premium_outlined),
          title: Text(l10n.profilePlan),
          subtitle: Text(_planDescription(context, subscription)),
          trailing: canDiscoverPremium ? const Icon(Icons.chevron_right) : null,
          onTap: canDiscoverPremium
              ? () => context.push(AppRoutes.paywall)
              : null,
        ),
        if (subscription != null)
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: Text(l10n.profileManageSubscription),
            onTap: () => ref.read(urlOpenerProvider)(subscriptionManagementUrl),
          ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: Text(l10n.paywallRestore),
          enabled: !isRestoring,
          onTap: () => _restore(context, ref),
        ),
      ],
    );
  }

  String _planDescription(BuildContext context, Subscription? subscription) {
    final l10n = AppLocalizations.of(context);
    if (subscription == null) return l10n.profilePlanFree;

    final date = MaterialLocalizations.of(
      context,
    ).formatShortDate(subscription.expiresAt.toLocal());
    final plan = l10n.profilePlanPremium(planName(l10n, subscription.plan));
    final deadline = subscription.inTrial
        ? l10n.profilePlanTrialUntil(date)
        : l10n.profilePlanUntil(date);
    return '$plan\n$deadline';
  }
}
