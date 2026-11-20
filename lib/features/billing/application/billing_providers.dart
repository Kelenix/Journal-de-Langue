import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../../core/utils/clock.dart';
import '../../auth/application/auth_providers.dart';
import '../../languages/application/language_providers.dart';
import '../data/supabase_subscription_repository.dart';
import '../data/supabase_wallet_repository.dart';
import '../data/unavailable_billing_repository.dart';
import '../domain/billing_repository.dart';
import '../domain/offer.dart';
import '../domain/subscription.dart';
import '../domain/wallet.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SupabaseSubscriptionRepository(ref.watch(supabaseClientProvider)),
);

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => SupabaseWalletRepository(ref.watch(supabaseClientProvider)),
);

/// Achats à l'unité de l'utilisateur connecté ; vide s'il n'est pas connecté.
final walletProvider = FutureProvider.autoDispose<Wallet>((ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return const Wallet();
  return ref.watch(walletRepositoryProvider).current();
}, retry: (retryCount, error) => null);

/// Achats auprès du store. Indisponibles tant que l'app n'est pas reliée à
/// RevenueCat (ADR-021) ; remplacé dans les tests.
final billingRepositoryProvider = Provider<BillingRepository>(
  (ref) => const UnavailableBillingRepository(),
);

/// Abonnement connu du serveur ; `null` avec l'offre gratuite.
final subscriptionProvider = FutureProvider.autoDispose<Subscription?>(
  (ref) async {
    final userId = await ref.watch(currentUserIdProvider.future);
    if (userId == null) return null;
    return ref.watch(subscriptionRepositoryProvider).current();
  },
  // Pas de nouvel essai automatique : l'écran propose « Réessayer ».
  retry: (retryCount, error) => null,
);

/// Abonnement Premium en cours de validité, ou `null`.
///
/// Une fonction et non un provider : avec flutter_riverpod 3.3.2, un provider
/// qui en observe un autre ne doit pas être recalculé pendant qu'un écran
/// redevient visible (ADR-022).
Subscription? watchActiveSubscription(WidgetRef ref) {
  final subscription = ref.watch(subscriptionProvider).value;
  final now = ref.watch(clockProvider)();
  return subscription != null && subscription.isActiveAt(now)
      ? subscription
      : null;
}

/// Ordre de présentation : annuel mis en avant, puis mensuel, puis
/// hebdomadaire (INTAKE §9).
const _presentationOrder = [
  SubscriptionPlan.annual,
  SubscriptionPlan.monthly,
  SubscriptionPlan.weekly,
];

final offersProvider = FutureProvider.autoDispose<List<Offer>>((ref) async {
  final offers = await ref.watch(billingRepositoryProvider).offers();
  return [...offers]..sort(
    (a, b) => _presentationOrder
        .indexOf(a.plan)
        .compareTo(_presentationOrder.indexOf(b.plan)),
  );
}, retry: (retryCount, error) => null);

/// Achat et restauration depuis l'écran d'offres.
class PaywallController extends Notifier<AsyncValue<void>> {
  /// Le serveur apprend l'achat par une notification du store, qui peut suivre
  /// l'achat de quelques secondes.
  static const _confirmationAttempts = 5;
  static const _restoreAttempts = 3;
  static const _confirmationDelay = Duration(seconds: 2);

  @override
  AsyncValue<void> build() => const AsyncData(null);

  BillingRepository get _billing => ref.read(billingRepositoryProvider);

  /// Retourne `true` si Premium est actif à l'issue de l'achat.
  Future<bool> purchase(Offer offer) => _run(() async {
    final outcome = await _billing.purchase(offer);
    if (outcome == PurchaseOutcome.cancelledByUser) return false;
    if (await _isPremiumConfirmed(_confirmationAttempts)) return true;
    throw const PurchasePendingFailure();
  });

  /// Retourne `true` si un abonnement en cours a été retrouvé.
  Future<bool> restore() => _run(() async {
    await _billing.restore();
    if (await _isPremiumConfirmed(_restoreAttempts)) return true;
    throw const NothingToRestoreFailure();
  });

  Future<bool> _run(Future<bool> Function() action) async {
    // Gardé jusqu'au bout : les offres ont pu être refermées pendant la
    // confirmation, l'offre et les langues doivent quand même être relues.
    final link = ref.keepAlive();
    try {
      state = const AsyncLoading();
      final result = await AsyncValue.guard(action);
      state = result.hasError
          ? AsyncError(result.error!, result.stackTrace!)
          : const AsyncData(null);
      return result.value ?? false;
    } finally {
      link.close();
    }
  }

  Future<bool> _isPremiumConfirmed(int attempts) async {
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (attempt > 0) await Future<void>.delayed(_confirmationDelay);
      final subscription = await ref
          .read(subscriptionRepositoryProvider)
          .current();
      final now = ref.read(clockProvider)();
      if (subscription != null && subscription.isActiveAt(now)) {
        // Tout ce qui dépend de l'offre se recharge. L'offre est relue tout de
        // suite, avant le retour à l'écran précédent (ADR-022).
        ref.invalidate(subscriptionProvider);
        await ref.read(subscriptionProvider.future);
        // L'offre fixe aussi le nombre de langues utilisables.
        await ref.read(activeLanguagesProvider.notifier).reload();
        return true;
      }
    }
    return false;
  }
}

final paywallControllerProvider =
    NotifierProvider.autoDispose<PaywallController, AsyncValue<void>>(
      PaywallController.new,
    );
