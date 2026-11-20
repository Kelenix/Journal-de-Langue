import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/external_links.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/settings_group.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../ads/application/ads_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../billing/application/billing_providers.dart';
import '../../billing/domain/subscription.dart';
import '../../billing/domain/wallet.dart';
import '../../billing/presentation/offer_labels.dart';
import '../../journal/application/journal_providers.dart';
import '../../languages/application/language_providers.dart';
import '../../languages/presentation/language_choice_list.dart';
import '../../languages/presentation/language_labels.dart';
import '../../languages/presentation/language_manager.dart';
import '../../legal/domain/legal_document.dart';
import '../../legal/presentation/legal_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languages = ref.watch(activeLanguagesProvider).value ?? const [];
    final isBusy = ref.watch(accountControllerProvider).isLoading;
    final isRestoring = ref.watch(paywallControllerProvider).isLoading;
    final wallet = ref.watch(walletProvider).value ?? const Wallet();
    final email = ref.watch(currentEmailProvider);
    // Achats à l'unité : présentés après une première correction, ou à qui
    // en a déjà.
    final showsShop = watchHasCorrectedJournal(ref) || !wallet.isEmpty;
    // Choix de consentement aux publicités, là où la loi demande de pouvoir
    // les revoir (US-22).
    final showsAdPrivacy =
        watchAdsVisible(ref) &&
        (ref.watch(adPrivacyRequiredProvider).value ?? false);

    ref.listen(accountControllerProvider, (_, next) {
      final error = next.error;
      if (error == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage(l10n, error))));
    });

    return Scaffold(
      appBar: TabAppBar(
        title: l10n.tabProfile,
        subtitle: email,
        leading: _Avatar(email: email),
      ),
      body: ListView(
        padding: tabPagePadding,
        children: [
          const _PlanCard(),
          const SizedBox(height: AppSpacing.lg),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.translate,
                title: l10n.profileLanguages(languages.length),
                subtitle: languages.isEmpty
                    ? null
                    : [
                        for (final language in languages)
                          languageName(l10n, language),
                      ].join(', '),
                onTap: () => _showLanguagePicker(context),
              ),
              if (showsShop)
                SettingsTile(
                  icon: Icons.shopping_bag_outlined,
                  warm: true,
                  title: l10n.shopTitle,
                  subtitle: wallet.isEmpty
                      ? null
                      : [
                          if (wallet.correctionCredits > 0)
                            l10n.shopCredits(wallet.correctionCredits),
                          if (wallet.examCredits > 0)
                            l10n.shopExamCredits(wallet.examCredits),
                          if (wallet.adsRemoved) l10n.shopAdsRemoved,
                        ].join(' · '),
                  onTap: () => context.push(AppRoutes.shop),
                ),
              SettingsTile(
                icon: Icons.restore,
                title: l10n.paywallRestore,
                onTap: isRestoring ? null : () => _restore(context, ref),
              ),
              if (showsAdPrivacy)
                SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.profileAdPrivacy,
                  onTap: () =>
                      ref.read(adsServiceProvider).showPrivacyOptions(),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsGroup(
            children: [
              for (final document in LegalDocument.values)
                SettingsTile(
                  icon: legalIcon(document),
                  title: legalTitle(l10n, document),
                  onTap: () => context.push(AppRoutes.legalOf(document)),
                ),
              SettingsTile(
                icon: Icons.info_outline,
                title: l10n.aboutApp,
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: l10n.appTitle,
                  children: [Text(l10n.appTagline)],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.logout,
                title: l10n.profileSignOut,
                onTap: isBusy
                    ? null
                    : () => ref
                          .read(accountControllerProvider.notifier)
                          .signOut(),
              ),
              SettingsTile(
                icon: Icons.delete_outline,
                title: l10n.profileDeleteAccount,
                isDestructive: true,
                onTap: isBusy
                    ? null
                    : () => _confirmAccountDeletion(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  Future<void> _showLanguagePicker(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: _LanguageSheet(),
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

/// Initiale du compte sur une pastille verte.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.email});

  static const _radius = 26.0;

  final String? email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final initial = email?.characters.firstOrNull?.toUpperCase();
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: _radius,
        backgroundColor: colors.hero,
        foregroundColor: colors.onHero,
        child: initial == null
            ? const Icon(Icons.person_outline)
            : Text(
                initial,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.onHero,
                ),
              ),
      ),
    );
  }
}

/// Offre de l'utilisateur, sur l'aplat vert : découvrir Premium, ou gérer
/// son abonnement.
class _PlanCard extends ConsumerWidget {
  const _PlanCard();

  static const _badgeSize = 40.0;
  static const _actionHeight = 48.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final subscription = watchActiveSubscription(ref);
    // Les offres payantes ne sont jamais proposées avant une première
    // correction (INTAKE §6).
    final canDiscoverPremium =
        subscription == null && watchHasCorrectedJournal(ref);

    return HeroCard(
      onTap: canDiscoverPremium ? () => context.push(AppRoutes.paywall) : null,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final colors = theme.extension<AppColors>()!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: _badgeSize,
                      height: _badgeSize,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Icon(
                        Icons.workspace_premium_outlined,
                        color: colors.onAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profilePlan,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          _planDescription(context, subscription),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Toute la carte ouvre les offres : ce rappel n'est pas un
              // bouton de plus.
              if (canDiscoverPremium) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  height: _actionHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.onHero,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Text(
                    l10n.paywallDiscover,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.hero,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (subscription != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () =>
                      ref.read(urlOpenerProvider)(subscriptionManagementUrl),
                  child: Text(l10n.profileManageSubscription),
                ),
              ],
            ],
          );
        },
      ),
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

/// Gratuit : une langue à la fois, choisie dans la liste. Premium : plusieurs
/// langues (US-04).
class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isPremium = watchActiveSubscription(ref) != null;

    if (isPremium) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.profileLanguagesPremiumNote),
          const SizedBox(height: AppSpacing.lg),
          const LanguageManager(),
        ],
      );
    }

    final current = ref.watch(activeLanguagesProvider).value?.firstOrNull;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.profileChangeLanguageNote),
        const SizedBox(height: AppSpacing.lg),
        LanguageChoiceList(
          selected: current,
          onActivated: () => Navigator.of(context).pop(),
        ),
        // Jamais d'offre payante avant une première correction (INTAKE §6).
        if (watchHasCorrectedJournal(ref)) ...[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.paywall);
            },
            child: Text(l10n.languagesPremiumHint),
          ),
        ],
      ],
    );
  }
}
