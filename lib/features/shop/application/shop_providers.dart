import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../ads/application/ads_providers.dart';
import '../../billing/application/billing_providers.dart';
import '../../billing/domain/billing_repository.dart';
import '../../billing/domain/one_time_product.dart';
import '../../journal/application/journal_providers.dart';
import '../../languages/application/language_providers.dart';

/// Produits vendus à l'unité, dans l'ordre de présentation de la boutique.
final productOffersProvider = FutureProvider.autoDispose<List<ProductOffer>>((
  ref,
) async {
  final offers = await ref.watch(billingRepositoryProvider).products();
  return [...offers]
    ..sort((a, b) => a.product.index.compareTo(b.product.index));
}, retry: (retryCount, error) => null);

/// Achat d'un produit à l'unité et restauration des achats (US-18 à 21).
class ShopController extends Notifier<AsyncValue<void>> {
  /// Le serveur apprend l'achat par une notification du store, qui peut suivre
  /// l'achat de quelques secondes.
  static const _confirmationAttempts = 5;
  static const _confirmationDelay = Duration(seconds: 2);

  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Retourne `true` si l'achat est confirmé par le serveur.
  Future<bool> buy(OneTimeProduct product) => _run(() async {
    final wallets = ref.read(walletRepositoryProvider);
    final before = await wallets.current();
    final outcome = await ref.read(billingRepositoryProvider).buy(product);
    if (outcome == PurchaseOutcome.cancelledByUser) return false;

    for (var attempt = 0; attempt < _confirmationAttempts; attempt++) {
      await Future<void>.delayed(_confirmationDelay);
      if (await wallets.current() != before) {
        await _reloadPurchases();
        return true;
      }
    }
    throw const PurchasePendingFailure();
  });

  /// Retourne `true` une fois les achats relus.
  Future<bool> restore() => _run(() async {
    await ref.read(billingRepositoryProvider).restore();
    await _reloadPurchases();
    return true;
  });

  /// Les achats changent les crédits du jour, les langues et le portefeuille.
  /// Les langues, observées par d'autres providers, sont relues tout de suite
  /// (ADR-022).
  Future<void> _reloadPurchases() async {
    ref
      ..invalidate(walletProvider)
      ..invalidate(journalDayProvider)
      ..invalidate(adStatusProvider);
    await ref.read(activeLanguagesProvider.notifier).reload();
  }

  Future<bool> _run(Future<bool> Function() action) async {
    // Gardé jusqu'au bout : la boutique a pu être refermée pendant l'achat,
    // les achats doivent quand même être relus.
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
}

final shopControllerProvider =
    NotifierProvider.autoDispose<ShopController, AsyncValue<void>>(
      ShopController.new,
    );
