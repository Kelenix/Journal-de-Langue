import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../../billing/application/billing_providers.dart';
import '../data/admob_ads_service.dart';
import '../data/supabase_ads_repository.dart';
import '../domain/ad_status.dart';
import '../domain/ads_service.dart';

final adsRepositoryProvider = Provider<AdsRepository>(
  (ref) => SupabaseAdsRepository(ref.watch(supabaseClientProvider)),
);

final adsServiceProvider = Provider<AdsService>(
  (ref) => AdmobAdsService(AdUnits.forThisBuild()),
);

/// Publicités de l'utilisateur connecté, décidées par le serveur. Recalculé
/// quand l'utilisateur ou son offre change.
final adStatusProvider = FutureProvider.autoDispose<AdStatus>((ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return const AdStatus();
  await ref.watch(subscriptionProvider.future);
  return ref.watch(adsRepositoryProvider).status();
}, retry: (retryCount, error) => null);

/// Consentement recueilli et SDK prêt : demandé une fois par session, et
/// seulement à qui verra des publicités.
final adsReadyProvider = FutureProvider<bool>(
  (ref) => ref.watch(adsServiceProvider).prepare(),
  retry: (retryCount, error) => null,
);

/// Vrai si l'utilisateur doit pouvoir revoir ses choix de consentement.
final adPrivacyRequiredProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(adsServiceProvider).isPrivacyOptionsRequired(),
  retry: (retryCount, error) => null,
);

/// Vrai si des publicités peuvent être montrées maintenant. Une fonction et
/// non un provider (ADR-022).
bool watchAdsVisible(WidgetRef ref) {
  final status = ref.watch(adStatusProvider).value;
  if (status == null || !status.adsEnabled) return false;
  return ref.watch(adsReadyProvider).value ?? false;
}

/// Issue d'une demande de récompense par vidéo.
enum RewardResult {
  /// Le serveur a accordé la récompense.
  granted,

  /// Vidéo vue, mais le serveur n'a pas encore reçu la confirmation d'AdMob.
  pending,
  notEarned,
  unavailable,
}

/// Interstitiel après une correction et vidéos récompensées (US-22, US-23).
class AdsController extends Notifier<bool> {
  /// AdMob confirme la récompense au serveur quelques secondes après la vidéo.
  static const _confirmationAttempts = 5;
  static const _confirmationDelay = Duration(seconds: 2);

  /// Vrai une fois l'interstitiel de la session montré : au plus un par
  /// session (INTAKE §5.1).
  @override
  bool build() => false;

  AdsService get _service => ref.read(adsServiceProvider);

  /// À appeler en quittant une correction, jamais pendant sa lecture.
  Future<void> afterCorrection() async {
    if (state) return;
    try {
      final status = await ref.read(adStatusProvider.future);
      if (!status.adsEnabled || !await _service.prepare()) return;
      if (await _service.showInterstitial()) state = true;
    } on Failure {
      // Statut des publicités illisible : pas d'interstitiel, rien d'autre.
    }
  }

  Future<RewardResult> watchRewarded(AdRewardKind kind) async {
    final userId = ref.read(currentUserIdProvider).value;
    if (userId == null) return RewardResult.unavailable;

    final repository = ref.read(adsRepositoryProvider);
    final before = (await repository.status()).rewardsLeft(kind);
    final outcome = await _service.showRewarded(userId: userId, kind: kind);
    switch (outcome) {
      case RewardedOutcome.unavailable:
        return RewardResult.unavailable;
      case RewardedOutcome.notEarned:
        return RewardResult.notEarned;
      case RewardedOutcome.earned:
        break;
    }

    for (var attempt = 0; attempt < _confirmationAttempts; attempt++) {
      await Future<void>.delayed(_confirmationDelay);
      try {
        if ((await repository.status()).rewardsLeft(kind) > before) {
          ref.invalidate(adStatusProvider);
          return RewardResult.granted;
        }
      } on Failure {
        // Réseau coupé après la vidéo : AdMob prévient quand même le serveur,
        // « Actualiser » la montrera.
        return RewardResult.pending;
      }
    }
    return RewardResult.pending;
  }
}

final adsControllerProvider = NotifierProvider<AdsController, bool>(
  AdsController.new,
);
