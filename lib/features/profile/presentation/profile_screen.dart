import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final wallet = ref.watch(walletProvider).value ?? const Wallet();
    final email = ref.watch(currentEmailProvider);
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
      // Sur un écran plus haut que la maquette, la place libre se répartit
      // entre les blocs au lieu de rester en bas (ADR-042).
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: tabPagePadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - tabPagePadding.vertical)
                  .clamp(0, double.infinity),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _PlanCard(),
                const SizedBox(height: AppSpacing.lg),
                SettingsGroup(
                  children: [
                    SettingsTile(
                      icon: Icons.language,
                      title: l10n.profileLanguagesTitle,
                      value: languages.isEmpty
                          ? null
                          : [
                              for (final language in languages)
                                languageName(l10n, language),
                            ].join(', '),
                      onTap: () => _showLanguagePicker(context),
                    ),
                    // Les achats à l'unité et leur restauration.
                    SettingsTile(
                      icon: Icons.shopping_bag_outlined,
                      warm: true,
                      title: l10n.profilePurchases,
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
                      icon: Icons.shield_outlined,
                      title: l10n.profilePrivacy,
                      onTap: () => _showPrivacy(
                        context,
                        ref,
                        showsAdPrivacy: showsAdPrivacy,
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
                      plain: true,
                      onTap: isBusy
                          ? null
                          : () => ref
                                .read(accountControllerProvider.notifier)
                                .signOut(),
                    ),
                    SettingsTile(
                      icon: Icons.delete_outline,
                      title: l10n.profileDeleteAccount,
                      plain: true,
                      isDestructive: true,
                      onTap: isBusy
                          ? null
                          : () => _confirmAccountDeletion(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
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

  /// Textes légaux, choix publicitaires et informations sur l'app.
  Future<void> _showPrivacy(
    BuildContext context,
    WidgetRef ref, {
    required bool showsAdPrivacy,
  }) {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        // Ferme la feuille, puis ouvre la page choisie depuis le profil.
        VoidCallback then(VoidCallback open) => () {
          Navigator.of(sheetContext).pop();
          open();
        };
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.sm,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.profilePrivacy,
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                  ),
                ),
                for (final document in LegalDocument.values)
                  ListTile(
                    leading: Icon(legalIcon(document)),
                    title: Text(legalTitle(l10n, document)),
                    onTap: then(
                      () => context.push(AppRoutes.legalOf(document)),
                    ),
                  ),
                if (showsAdPrivacy)
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(l10n.profileAdPrivacy),
                    onTap: then(
                      () => ref.read(adsServiceProvider).showPrivacyOptions(),
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.aboutApp),
                  onTap: then(
                    () => showAboutDialog(
                      context: context,
                      applicationName: l10n.appTitle,
                      children: [Text(l10n.appTagline)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

/// Offre de l'utilisateur, sur l'aplat vert : ce que Premium ajoute, ou
/// l'abonnement en cours. Les offres ne s'ouvrent que si on les demande
/// (ADR-040).
class _PlanCard extends ConsumerWidget {
  const _PlanCard();

  static const _badgeSize = 40.0;
  static const _crownSize = 22.0;
  static const _titleSize = 18.0;
  static const _detailSize = 13.0;
  static const _pitchSize = 14.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final subscription = watchActiveSubscription(ref);

    return HeroCard(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final colors = theme.extension<AppColors>()!;
          final muted = theme.colorScheme.onSurfaceVariant;
          final (title, detail) = subscription == null
              ? (l10n.profilePlanFreeTitle, l10n.profilePlanFreeDetail)
              : (
                  l10n.profilePlanPremium(planName(l10n, subscription.plan)),
                  _deadline(context, subscription),
                );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: _badgeSize,
                      height: _badgeSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: CustomPaint(
                        size: const Size.square(_crownSize),
                        painter: _CrownPainter(colors.onAccent),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: MergeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: _titleSize,
                            ),
                          ),
                          Text(
                            detail,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: _detailSize,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (subscription == null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.profilePremiumPitch,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: _pitchSize,
                    color: muted,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (subscription == null)
                FilledButton(
                  onPressed: () => context.push(AppRoutes.paywall),
                  child: Text(l10n.paywallDiscover),
                )
              else
                FilledButton(
                  onPressed: () =>
                      ref.read(urlOpenerProvider)(subscriptionManagementUrl),
                  child: Text(l10n.profileManageSubscription),
                ),
            ],
          );
        },
      ),
    );
  }

  String _deadline(BuildContext context, Subscription subscription) {
    final l10n = AppLocalizations.of(context);
    final date = MaterialLocalizations.of(
      context,
    ).formatShortDate(subscription.expiresAt.toLocal());
    return subscription.inTrial
        ? l10n.profilePlanTrialUntil(date)
        : l10n.profilePlanUntil(date);
  }
}

/// Couronne de l'offre, au trait comme les icônes « outlined ».
class _CrownPainter extends CustomPainter {
  const _CrownPainter(this.color);

  // Tracé sur une grille de 24, comme les icônes Material.
  static const _grid = 24.0;
  static const _stroke = 1.8;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _grid);
    final crown = Path()
      ..moveTo(4, 8)
      ..lineTo(8, 11.5)
      ..lineTo(12, 5)
      ..lineTo(16, 11.5)
      ..lineTo(20, 8)
      ..lineTo(18.5, 18)
      ..lineTo(5.5, 18)
      ..close();
    canvas.drawPath(
      crown,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CrownPainter oldDelegate) => oldDelegate.color != color;
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
        // Rappel en contexte : seulement après une première correction
        // (ADR-040).
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
