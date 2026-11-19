import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/offer.dart';
import '../domain/subscription.dart';

const _monthsPerYear = 12;

String planName(AppLocalizations l10n, SubscriptionPlan plan) => switch (plan) {
  SubscriptionPlan.weekly => l10n.planWeekly,
  SubscriptionPlan.monthly => l10n.planMonthly,
  SubscriptionPlan.annual => l10n.planAnnual,
};

/// Prix réel et période de facturation, tels qu'exigés par les stores :
/// « 29,99 € par an ».
String priceWithPeriod(AppLocalizations l10n, Offer offer) =>
    switch (offer.plan) {
      SubscriptionPlan.weekly => l10n.pricePerWeek(offer.priceLabel),
      SubscriptionPlan.monthly => l10n.pricePerMonth(offer.priceLabel),
      SubscriptionPlan.annual => l10n.pricePerYear(offer.priceLabel),
    };

/// Équivalent mensuel de l'offre annuelle, dans la devise du store.
String monthlyEquivalent(Offer annualOffer, String locale) =>
    NumberFormat.simpleCurrency(
      locale: locale,
      name: annualOffer.currencyCode,
    ).format(annualOffer.price / _monthsPerYear);
