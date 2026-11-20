import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/error_message.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../legal/presentation/legal_screen.dart';
import '../application/billing_providers.dart';
import '../domain/offer.dart';
import '../domain/subscription.dart';
import 'offer_labels.dart';

/// Offres Premium (US-10, US-11). Toujours ouvert à la demande de
/// l'utilisateur, jamais avant sa première correction, et toujours refermable.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const SoftAppBar(),
      body: SafeArea(
        top: false,
        child: AsyncView(
          value: ref.watch(offersProvider),
          onRetry: () => ref.invalidate(offersProvider),
          builder: (offers) => _Offers(offers: offers),
        ),
      ),
    );
  }
}

class _Offers extends ConsumerStatefulWidget {
  const _Offers({required this.offers});

  /// Triées : la première est l'offre mise en avant.
  final List<Offer> offers;

  @override
  ConsumerState<_Offers> createState() => _OffersState();
}

class _OffersState extends ConsumerState<_Offers> {
  static const _crownRadius = 24.0;

  late Offer _selected = widget.offers.first;

  Future<void> _activate(Future<bool> Function() action) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    if (!await action()) return;

    messenger.showSnackBar(SnackBar(content: Text(l10n.paywallWelcome)));
    // Offres déjà refermées pendant la confirmation : rien d'autre à fermer.
    if (mounted) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final action = ref.watch(paywallControllerProvider);
    final controller = ref.read(paywallControllerProvider.notifier);
    final error = action.error;
    final trialDays = _selected.trialDays;
    final price = priceWithPeriod(l10n, _selected);

    // Contenu court et fini : une colonne défilante, pas une liste paresseuse.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroCard(
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final colors = theme.extension<AppColors>()!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: CircleAvatar(
                        radius: _crownRadius,
                        backgroundColor: colors.accent,
                        foregroundColor: colors.onAccent,
                        child: const Icon(Icons.workspace_premium_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.paywallTitle,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final benefit in [
                      l10n.paywallBenefitUnlimited,
                      l10n.paywallBenefitLonger,
                      l10n.paywallBenefitAdvanced,
                      l10n.paywallBenefitExercises,
                      l10n.paywallBenefitLanguages,
                      l10n.paywallBenefitHistory,
                    ])
                      _Benefit(benefit),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final offer in widget.offers)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _OfferCard(
                offer: offer,
                isSelected: offer == _selected,
                isHighlighted: offer == widget.offers.first,
                onSelected: action.isLoading
                    ? null
                    : () => setState(() => _selected = offer),
              ),
            ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ErrorMessage(failureMessage(l10n, error)),
          ],
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: trialDays == null
                ? l10n.paywallSubscribe
                : l10n.paywallStartTrial(trialDays),
            isLoading: action.isLoading,
            onPressed: () => _activate(() => controller.purchase(_selected)),
          ),
          const SizedBox(height: AppSpacing.md),
          // Prix réel, période, essai, renouvellement et annulation (INTAKE §10.1).
          Text(
            trialDays == null
                ? l10n.paywallTerms(price)
                : l10n.paywallTermsTrial(trialDays, price),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: action.isLoading
                ? null
                : () => _activate(controller.restore),
            child: Text(l10n.paywallRestore),
          ),
          // Exigés par les stores pour les abonnements.
          const LegalLinks(),
        ],
      ),
    );
  }
}

/// Un avantage de Premium, coché en corail sur l'aplat vert.
class _Benefit extends StatelessWidget {
  const _Benefit(this.label);

  static const _checkSize = 22.0;
  static const _checkIconSize = 14.0;

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: _checkSize,
              height: _checkSize,
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: _checkIconSize,
                color: colors.onAccent,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.isSelected,
    required this.isHighlighted,
    required this.onSelected,
  });

  static const _selectedBorderWidth = 2.0;

  final Offer offer;
  final bool isSelected;

  /// Offre présentée comme la plus avantageuse.
  final bool isHighlighted;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? _selectedBorderWidth : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        selected: isSelected,
        onTap: onSelected,
        leading: Icon(
          isSelected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
        ),
        title: Text(
          planName(l10n, offer.plan),
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          offer.plan == SubscriptionPlan.annual
              ? '${priceWithPeriod(l10n, offer)}\n'
                    '${l10n.paywallAnnualEquivalent(monthlyEquivalent(offer, locale))}'
              : priceWithPeriod(l10n, offer),
        ),
        trailing: isHighlighted
            ? Chip(
                label: Text(l10n.paywallBestValue),
                backgroundColor: colors.accent,
                side: BorderSide.none,
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onAccent,
                ),
              )
            : null,
      ),
    );
  }
}
