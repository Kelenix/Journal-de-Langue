import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/features/ads/domain/ad_status.dart';
import 'package:journal_de_langue/features/ads/domain/ads_service.dart';
import 'package:journal_de_langue/features/billing/domain/wallet.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';

import 'support/fakes.dart';
import 'support/pump_app.dart';

/// Publicités discrètes et vidéos récompensées, sur des données en mémoire
/// (US-22, US-23).
void main() {
  late FakeAuthRepository auth;
  late FakeLanguageRepository languages;
  late FakeSubscriptionRepository subscriptions;
  late FakeWalletRepository wallet;
  late FakeJournalRepository journal;
  late FakeExerciseRepository exercises;
  late FakeAdsRepository adsRepository;
  late FakeAdsService ads;

  setUp(() {
    auth = FakeAuthRepository(userId: FakeAuthRepository.signedInUserId);
    subscriptions = FakeSubscriptionRepository();
    languages = FakeLanguageRepository([
      LearningLanguage.english,
    ], subscriptions);
    wallet = FakeWalletRepository();
    journal = FakeJournalRepository(
      subscriptions: subscriptions,
      wallet: wallet,
    );
    exercises = FakeExerciseRepository(subscriptions: subscriptions);
    adsRepository = FakeAdsRepository(FakeAdsRepository.eligible);
    ads = FakeAdsService()
      // Comme le serveur à la confirmation d'AdMob.
      ..onEarned = (kind) {
        switch (kind) {
          case AdRewardKind.correction:
            journal.rewardCorrections++;
            adsRepository.adStatus = adsRepository.adStatus.copyWith(
              correctionRewardAvailable: false,
              rewardCorrections: adsRepository.adStatus.rewardCorrections + 1,
            );
          case AdRewardKind.exercises:
            exercises.bonus += 3;
            adsRepository.adStatus = adsRepository.adStatus.copyWith(
              exercisesRewardAvailable: false,
              rewardExercises: adsRepository.adStatus.rewardExercises + 3,
            );
        }
      };
  });

  Future<void> pump(WidgetTester tester) => pumpApp(
    tester,
    auth: auth,
    languages: languages,
    journal: journal,
    subscriptions: subscriptions,
    wallet: wallet,
    exercises: exercises,
    adsRepository: adsRepository,
    ads: ads,
  );

  Future<void> tapText(WidgetTester tester, String text) =>
      tapOn(tester, find.text(text));

  final banner = find.byKey(FakeAdsService.bannerKey);

  Future<void> correctTodaysJournal(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'I has a cat.');
    await tester.pump();
    await tapOn(
      tester,
      find.widgetWithText(FilledButton, english.journalSubmit),
    );
    await tapText(tester, english.correctionDone);
  }

  /// Appuie sur [target] puis laisse passer [seconds] secondes d'attente de la
  /// confirmation par le serveur.
  Future<void> tapAndWait(
    WidgetTester tester,
    Finder target, {
    required int seconds,
  }) async {
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    for (var second = 0; second < seconds; second++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
  }

  group('bannière', () {
    testWidgets('en bas du journal, mais jamais pendant la saisie', (
      tester,
    ) async {
      await pump(tester);
      await tester.scrollUntilVisible(
        banner,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(banner, findsOneWidget);

      await tester.enterText(find.byType(TextField), 'I');
      await tester.pump();

      expect(banner, findsNothing);
    });

    testWidgets('aucune publicité sans y être éligible (Premium, sans '
        'publicité, 14 premiers jours)', (tester) async {
      adsRepository.adStatus = const AdStatus();
      await pump(tester);

      expect(banner, findsNothing);
    });

    testWidgets('aucune publicité tant que le consentement n\'est pas donné', (
      tester,
    ) async {
      ads.canRequestAds = false;
      await pump(tester);

      expect(banner, findsNothing);
    });
  });

  group('interstitiel', () {
    testWidgets('à la sortie d\'une correction, au plus une fois par '
        'session', (tester) async {
      wallet.wallet = const Wallet(correctionCredits: 1);
      await pump(tester);

      await correctTodaysJournal(tester);
      expect(ads.interstitialsShown, 1);

      await correctTodaysJournal(tester);
      expect(ads.interstitialsShown, 1);
    });

    testWidgets('jamais sans y être éligible', (tester) async {
      adsRepository.adStatus = const AdStatus();
      await pump(tester);

      await correctTodaysJournal(tester);

      expect(ads.interstitialsShown, 0);
    });
  });

  group('vidéo récompensée', () {
    testWidgets('à la limite du jour, une vidéo vue en entier rouvre le '
        'journal pour une correction', (tester) async {
      await pump(tester);
      await correctTodaysJournal(tester);

      await tapAndWait(
        tester,
        find.text(english.rewardWatchForCorrection),
        seconds: 3,
      );

      expect(ads.rewardedFor.single.kind, AdRewardKind.correction);
      expect(ads.rewardedFor.single.userId, FakeAuthRepository.signedInUserId);
      expect(find.text(english.rewardGranted), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(english.journalUsesReward), findsOneWidget);
      // Une seule par jour.
      expect(find.text(english.rewardWatchForCorrection), findsNothing);
    });

    testWidgets('une vidéo fermée avant la fin ne rapporte rien', (
      tester,
    ) async {
      ads.rewardedOutcome = RewardedOutcome.notEarned;
      await pump(tester);
      await correctTodaysJournal(tester);

      await tapAndWait(
        tester,
        find.text(english.rewardWatchForCorrection),
        seconds: 1,
      );

      expect(find.text(english.rewardNotEarned), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('si la confirmation tarde, l\'utilisateur est prévenu et '
        'peut vérifier plus tard', (tester) async {
      final serverConfirms = ads.onEarned!;
      ads.onEarned = null;
      await pump(tester);
      await correctTodaysJournal(tester);

      await tapAndWait(
        tester,
        find.text(english.rewardWatchForCorrection),
        seconds: 11,
      );

      expect(find.text(english.rewardPending), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      // La confirmation d'AdMob arrive enfin au serveur.
      serverConfirms(AdRewardKind.correction);
      await tapText(tester, english.rewardRefresh);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(english.journalUsesReward), findsOneWidget);
    });

    testWidgets('à la limite des exercices, une vidéo en donne 3 de plus', (
      tester,
    ) async {
      for (var index = 0; index < 3; index++) {
        await exercises.answer(
          exerciseId: 'exercise-$index',
          choice: FakeExerciseRepository.rightChoice,
          day: testNow,
        );
      }
      await pump(tester);
      await tapOn(tester, find.byIcon(Icons.copy_outlined));
      await tapText(tester, english.exercisesTitle);

      expect(find.text(english.exercisesLimitFree), findsOneWidget);

      await tapAndWait(
        tester,
        find.text(english.rewardWatchForExercises),
        seconds: 3,
      );

      expect(find.text(english.exerciseProgress(1, 3)), findsOneWidget);
    });
  });

  testWidgets('le profil permet de revoir ses choix de confidentialité là '
      'où c\'est exigé', (tester) async {
    ads.privacyOptionsRequired = true;
    await pump(tester);
    await tapOn(tester, find.byIcon(Icons.person_outline));
    await tapText(tester, english.profilePrivacy);

    await tapText(tester, english.profileAdPrivacy);

    expect(ads.privacyOptionsShown, 1);
  });
}
