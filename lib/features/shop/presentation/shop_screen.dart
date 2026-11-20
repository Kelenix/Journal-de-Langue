import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../billing/application/billing_providers.dart';
import '../../billing/domain/one_time_product.dart';
import '../../billing/domain/wallet.dart';
import '../../languages/presentation/language_labels.dart';
import '../application/shop_providers.dart';

/// Achats à l'unité : corrections, Pack Examinateur, accès à une langue,
/// sans publicité (US-18 à 21). Les prix sont ceux du store.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    ref.listen(shopControllerProvider, (_, next) {
      final error = next.error;
      if (error == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage(l10n, error))));
    });

    Future<void> restore() async {
      final messenger = ScaffoldMessenger.of(context);
      final isRestored = await ref
          .read(shopControllerProvider.notifier)
          .restore();
      if (isRestored) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.shopRestored)));
      }
    }

    return Scaffold(
      appBar: SoftAppBar(title: l10n.shopTitle),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            const _OwnedCard(),
            const SizedBox(height: AppSpacing.lg),
            AsyncView(
              value: ref.watch(productOffersProvider),
              onRetry: () => ref.invalidate(productOffersProvider),
              builder: (offers) => _Catalog(offers: offers),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: ref.watch(shopControllerProvider).isLoading
                  ? null
                  : restore,
              child: Text(l10n.paywallRestore),
            ),
            Text(
              l10n.shopOneTimeNote,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ce que l'utilisateur a déjà acheté et pas encore utilisé.
class _OwnedCard extends ConsumerWidget {
  const _OwnedCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final walletValue = ref.watch(walletProvider);
    final wallet = walletValue.value ?? const Wallet();
    final dates = MaterialLocalizations.of(context);

    final lines = [
      if (wallet.correctionCredits > 0)
        l10n.shopCredits(wallet.correctionCredits),
      if (wallet.examCredits > 0) l10n.shopExamCredits(wallet.examCredits),
      for (final pass in wallet.languagePasses)
        l10n.shopPassUntil(
          languageName(l10n, pass.language),
          dates.formatShortDate(pass.expiresAt.toLocal()),
        ),
      if (wallet.adsRemoved) l10n.shopAdsRemoved,
    ];

    return HeroCard(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.shopOwnedTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Achats pas encore lus : ni « rien pour l'instant », ni liste.
              if (!walletValue.hasValue || walletValue.hasError)
                AsyncView(
                  value: walletValue,
                  onRetry: () => ref.invalidate(walletProvider),
                  builder: (_) => const SizedBox.shrink(),
                )
              else if (lines.isEmpty)
                Text(
                  l10n.shopNothingOwned,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [for (final line in lines) Tag(line, warm: true)],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Catalog extends ConsumerWidget {
  const _Catalog({required this.offers});

  final List<ProductOffer> offers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Tant que les achats ne sont pas lus, « sans publicité » n'est pas
    // proposé : il est peut-être déjà acheté.
    final adsRemoved = ref.watch(walletProvider).value?.adsRemoved ?? true;

    List<ProductOffer> offersOf(bool Function(OneTimeProduct) matches) => [
      for (final offer in offers)
        if (matches(offer.product)) offer,
    ];

    final sections = [
      (
        icon: Icons.edit_note_outlined,
        title: l10n.shopCorrectionsTitle,
        body: l10n.shopCorrectionsBody,
        offers: offersOf(
          (product) =>
              product == OneTimeProduct.corrections10 ||
              product == OneTimeProduct.corrections50,
        ),
      ),
      (
        icon: Icons.school_outlined,
        title: l10n.productExamPack,
        body: l10n.productExamPackBody,
        offers: offersOf((product) => product == OneTimeProduct.examPack),
      ),
      (
        icon: Icons.translate,
        title: l10n.shopLanguagePassTitle,
        body: l10n.shopLanguagePassBody,
        offers: offersOf((product) => product.passLanguage != null),
      ),
      if (!adsRemoved)
        (
          icon: Icons.block_outlined,
          title: l10n.shopAdsRemoved,
          body: l10n.shopRemoveAdsBody,
          offers: offersOf((product) => product == OneTimeProduct.removeAds),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in sections)
          if (section.offers.isNotEmpty)
            _Section(
              icon: section.icon,
              title: section.title,
              body: section.body,
              offers: section.offers,
            ),
      ],
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.body,
    required this.offers,
  });

  static const _priceButtonSize = Size(96, 44);

  final IconData icon;
  final String title;
  final String body;
  final List<ProductOffer> offers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isBuying = ref.watch(shopControllerProvider).isLoading;

    Future<void> buy(OneTimeProduct product) async {
      final messenger = ScaffoldMessenger.of(context);
      final isConfirmed = await ref
          .read(shopControllerProvider.notifier)
          .buy(product);
      if (isConfirmed) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.shopPurchased)));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SoftCard(
        elevated: false,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBadge(icon),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          body,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final offer in offers)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                title: Text(productName(l10n, offer.product)),
                trailing: FilledButton.tonal(
                  // Le thème étire les boutons sur toute la largeur.
                  style: FilledButton.styleFrom(minimumSize: _priceButtonSize),
                  onPressed: isBuying ? null : () => buy(offer.product),
                  child: Text(offer.priceLabel),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Nom d'un produit tel qu'il apparaît dans la boutique.
String productName(AppLocalizations l10n, OneTimeProduct product) =>
    switch (product) {
      OneTimeProduct.corrections10 => l10n.productCorrections10,
      OneTimeProduct.corrections50 => l10n.productCorrections50,
      OneTimeProduct.examPack => l10n.productExamPack,
      OneTimeProduct.removeAds => l10n.shopAdsRemoved,
      OneTimeProduct.languagePassEnglish ||
      OneTimeProduct.languagePassSpanish ||
      OneTimeProduct.languagePassGerman ||
      OneTimeProduct.languagePassFrench => languageName(
        l10n,
        product.passLanguage!,
      ),
    };
