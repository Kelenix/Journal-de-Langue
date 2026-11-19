import 'package:freezed_annotation/freezed_annotation.dart';

import 'subscription.dart';

part 'offer.freezed.dart';

/// Un abonnement proposé à l'achat, tel que le store le décrit.
@freezed
abstract class Offer with _$Offer {
  const factory Offer({
    required SubscriptionPlan plan,

    /// Prix de la période, déjà mis en forme par le store (« 29,99 € »).
    required String priceLabel,
    required double price,

    /// Code ISO de la devise (« EUR »).
    required String currencyCode,

    /// Durée de l'essai gratuit ; `null` si l'utilisateur n'y a pas droit.
    int? trialDays,
  }) = _Offer;
}
