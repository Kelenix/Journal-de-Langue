import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../domain/ad_status.dart';
import '../domain/ads_service.dart';

/// Identifiants des blocs d'annonces, passés au build par `--dart-define`.
/// En développement, sans identifiant, ceux de démonstration de Google sont
/// utilisés ; en version publiée, un bloc absent n'est pas affiché.
@immutable
class AdUnits {
  const AdUnits({this.banner, this.interstitial, this.rewarded});

  factory AdUnits.forThisBuild() {
    // Blocs de démonstration : https://developers.google.com/admob/android/test-ads
    // et https://developers.google.com/admob/ios/test-ads
    final demo = Platform.isIOS
        ? const AdUnits(
            banner: 'ca-app-pub-3940256099942544/2934735716',
            interstitial: 'ca-app-pub-3940256099942544/4411468910',
            rewarded: 'ca-app-pub-3940256099942544/1712485313',
          )
        : const AdUnits(
            banner: 'ca-app-pub-3940256099942544/6300978111',
            interstitial: 'ca-app-pub-3940256099942544/1033173712',
            rewarded: 'ca-app-pub-3940256099942544/5224354917',
          );
    String? unit(String configured, String? demoUnit) => configured.isNotEmpty
        ? configured
        : kReleaseMode
        ? null
        : demoUnit;

    return AdUnits(
      banner: unit(
        const String.fromEnvironment('ADMOB_BANNER_ID'),
        demo.banner,
      ),
      interstitial: unit(
        const String.fromEnvironment('ADMOB_INTERSTITIAL_ID'),
        demo.interstitial,
      ),
      rewarded: unit(
        const String.fromEnvironment('ADMOB_REWARDED_ID'),
        demo.rewarded,
      ),
    );
  }

  final String? banner;
  final String? interstitial;
  final String? rewarded;
}

/// Publicités par le SDK Google Mobile Ads, consentement compris (UMP).
class AdmobAdsService implements AdsService {
  AdmobAdsService(this._units);

  final AdUnits _units;
  Future<bool>? _preparation;
  InterstitialAd? _interstitial;

  @override
  Future<bool> prepare() => _preparation ??= _prepare();

  Future<bool> _prepare() async {
    // Consentement demandé à chaque lancement, comme le recommande Google ; le
    // formulaire ne s'affiche que là où la loi l'exige.
    final gathered = Completer<void>();
    void done() {
      if (!gathered.isCompleted) gathered.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((_) => done()),
      (_) => done(),
    );
    await gathered.future;

    if (!await ConsentInformation.instance.canRequestAds()) return false;
    await MobileAds.instance.initialize();
    _loadInterstitial();
    return true;
  }

  @override
  Future<bool> isPrivacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  @override
  Future<void> showPrivacyOptions() {
    final closed = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((_) => closed.complete());
    return closed.future;
  }

  @override
  Widget banner() {
    final unit = _units.banner;
    return unit == null ? const SizedBox.shrink() : _AdmobBanner(unitId: unit);
  }

  void _loadInterstitial() {
    final unit = _units.interstitial;
    if (unit == null) return;
    InterstitialAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  @override
  Future<bool> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) return false;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, _) => ad.dispose(),
    );
    await ad.show();
    // Le suivant est préparé pour une prochaine session de l'app.
    _loadInterstitial();
    return true;
  }

  @override
  Future<RewardedOutcome> showRewarded({
    required String userId,
    required AdRewardKind kind,
  }) async {
    final unit = _units.rewarded;
    if (unit == null || !await prepare()) return RewardedOutcome.unavailable;

    final loaded = Completer<RewardedAd?>();
    await RewardedAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: loaded.complete,
        onAdFailedToLoad: (_) => loaded.complete(null),
      ),
    );
    final ad = await loaded.future;
    if (ad == null) return RewardedOutcome.unavailable;

    // Transmis par AdMob au serveur avec la récompense (fonction admob-reward).
    await ad.setServerSideOptions(
      ServerSideVerificationOptions(userId: userId, customData: kind.code),
    );
    var isEarned = false;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        closed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        closed.complete();
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => isEarned = true);
    await closed.future;
    return isEarned ? RewardedOutcome.earned : RewardedOutcome.notEarned;
  }
}

/// Bannière standard (320 × 50).
class _AdmobBanner extends StatefulWidget {
  const _AdmobBanner({required this.unitId});

  final String unitId;

  @override
  State<_AdmobBanner> createState() => _AdmobBannerState();
}

class _AdmobBannerState extends State<_AdmobBanner> {
  BannerAd? _ad;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _ad = BannerAd(
      adUnitId: widget.unitId,
      // Format standard, le plus discret (INTAKE §5).
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    );
    await _ad!.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_isLoaded) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
