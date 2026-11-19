import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/error_message.dart';
import '../../../shared/widgets/primary_button.dart';
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
      appBar: AppBar(leading: const CloseButton()),
      body: SafeArea(
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
  late Offer _selected = widget.offers.first;

  Future<void> _activate(Future<bool> Function() action) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    if (!await action()) return;

    messenger.showSnackBar(SnackBar(content: Text(l10n.paywallWelcome)));
    router.pop();
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.paywallTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          for (final benefit in [
            l10n.paywallBenefitUnlimited,
            l10n.paywallBenefitLonger,
            l10n.paywallBenefitHistory,
          ])
            _Benefit(benefit),
          const SizedBox(height: AppSpacing.lg),
          for (final offer in widget.offers)
            _OfferCard(
              offer: offer,
              isSelected: offer == _selected,
              isHighlighted: offer == widget.offers.first,
              onSelected: action.isLoading
                  ? null
                  : () => setState(() => _selected = offer),
            ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ErrorMessage(failureMessage(l10n, error)),
          ],
          const SizedBox(height: AppSpacing.lg),
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
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(Icons.check, color: theme.colorScheme.primary),
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
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? _selectedBorderWidth : 1,
        ),
      ),
      child: ListTile(
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
