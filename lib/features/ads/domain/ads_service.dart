import 'package:flutter/widgets.dart';

import 'ad_status.dart';

/// Ce que l'utilisateur a fait d'une vidéo récompensée.
enum RewardedOutcome {
  /// Vue en entier : AdMob en informe le serveur, qui accorde la récompense.
  earned,

  /// Fermée avant la fin.
  notEarned,

  /// Aucune vidéo à montrer pour l'instant.
  unavailable,
}

/// Publicités AdMob (US-22, US-23). Rien n'est montré avant [prepare].
abstract interface class AdsService {
  /// Demande le consentement là où la loi l'exige, puis prépare les
  /// publicités. Retourne `true` si des publicités peuvent être demandées.
  Future<bool> prepare();

  /// Vrai si l'utilisateur doit pouvoir revoir ses choix de confidentialité.
  Future<bool> isPrivacyOptionsRequired();

  Future<void> showPrivacyOptions();

  /// Bannière discrète ; vide tant qu'elle n'est pas chargée.
  Widget banner();

  /// Montre l'interstitiel préparé, s'il est prêt. Retourne `true` s'il a été
  /// montré.
  Future<bool> showInterstitial();

  /// Montre une vidéo récompensée. [userId] et [kind] accompagnent la vidéo
  /// jusqu'au serveur, qui accorde la récompense.
  Future<RewardedOutcome> showRewarded({
    required String userId,
    required AdRewardKind kind,
  });
}

/// Publicités et récompenses telles que le serveur les connaît.
abstract interface class AdsRepository {
  Future<AdStatus> status();
}
