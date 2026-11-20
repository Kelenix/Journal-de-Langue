import 'offer.dart';
import 'one_time_product.dart';
import 'subscription.dart';
import 'wallet.dart';

/// Issue d'une tentative d'achat qui n'a pas échoué.
enum PurchaseOutcome { completed, cancelledByUser }

/// Achats auprès du store. Toute méthode échoue avec une `Failure`.
abstract interface class BillingRepository {
  /// Abonnements proposés, avec les prix du store.
  Future<List<Offer>> offers();

  Future<PurchaseOutcome> purchase(Offer offer);

  /// Produits vendus à l'unité, avec les prix du store.
  Future<List<ProductOffer>> products();

  Future<PurchaseOutcome> buy(OneTimeProduct product);

  /// Rattache à ce compte les achats déjà faits avec le compte du store.
  Future<void> restore();
}

/// Abonnement de l'utilisateur connecté, tel que le serveur le connaît.
abstract interface class SubscriptionRepository {
  Future<Subscription?> current();
}

/// Achats à l'unité de l'utilisateur connecté, tels que le serveur les connaît.
abstract interface class WalletRepository {
  Future<Wallet> current();
}
