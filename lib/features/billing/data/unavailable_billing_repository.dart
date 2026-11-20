import '../../../core/errors/failure.dart';
import '../domain/billing_repository.dart';
import '../domain/one_time_product.dart';
import '../domain/offer.dart';

/// Achats indisponibles : utilisé tant que l'app n'est pas reliée à un store
/// (builds de développement, clés RevenueCat absentes). L'écran d'offres le dit
/// à l'utilisateur au lieu de proposer un achat qui ne peut pas aboutir.
class UnavailableBillingRepository implements BillingRepository {
  const UnavailableBillingRepository();

  @override
  Future<List<Offer>> offers() => throw const BillingUnavailableFailure();

  @override
  Future<PurchaseOutcome> purchase(Offer offer) =>
      throw const BillingUnavailableFailure();

  @override
  Future<List<ProductOffer>> products() =>
      throw const BillingUnavailableFailure();

  @override
  Future<PurchaseOutcome> buy(OneTimeProduct product) =>
      throw const BillingUnavailableFailure();

  @override
  Future<void> restore() => throw const BillingUnavailableFailure();
}
