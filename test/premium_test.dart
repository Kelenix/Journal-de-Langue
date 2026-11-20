import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/features/billing/domain/subscription.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';

import 'support/fakes.dart';
import 'support/pump_app.dart';

/// Offres Premium, achat et droits, sur des données en mémoire (US-10, US-11).
void main() {
  late FakeAuthRepository auth;
  late FakeLanguageRepository languages;
  late FakeSubscriptionRepository subscriptions;
  late FakeBillingRepository billing;
  late FakeJournalRepository journal;
  late List<Uri> openedUrls;

  setUp(() {
    auth = FakeAuthRepository(userId: FakeAuthRepository.signedInUserId);
    languages = FakeLanguageRepository([LearningLanguage.english]);
    subscriptions = FakeSubscriptionRepository();
    billing = FakeBillingRepository(subscriptions);
    journal = FakeJournalRepository(subscriptions: subscriptions);
    openedUrls = [];
  });

  Subscription activeSubscription({bool inTrial = false}) => Subscription(
    plan: SubscriptionPlan.annual,
    expiresAt: FakeSubscriptionRepository.farFuture,
    inTrial: inTrial,
  );

  Future<void> pump(WidgetTester tester) => pumpApp(
    tester,
    auth: auth,
    languages: languages,
    journal: journal,
    subscriptions: subscriptions,
    billing: billing,
    openedUrls: openedUrls,
  );

  Future<void> tapText(WidgetTester tester, String text) =>
      tapOn(tester, find.text(text));

  Future<void> openTab(WidgetTester tester, IconData icon) =>
      tapOn(tester, find.byIcon(icon));

  /// Fait corriger le journal du jour : la limite gratuite est atteinte.
  Future<void> reachDailyLimit(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'I has a cat.');
    await tester.pump();
    await tapOn(
      tester,
      find.widgetWithText(FilledButton, english.journalSubmit),
    );
    await tapText(tester, english.correctionDone);
  }

  Future<void> openPaywall(WidgetTester tester) async {
    await pump(tester);
    await reachDailyLimit(tester);
    await tapText(tester, english.paywallDiscover);
  }

  /// Appuie sur [target] puis laisse passer [seconds] secondes d'attente de
  /// confirmation, sans attendre la fin des animations.
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
    await tester.pump();
  }

  group('avant la première correction', () {
    testWidgets('les offres ne s\'ouvrent pas d\'elles-mêmes ; le profil '
        'permet de les découvrir', (tester) async {
      await pump(tester);
      expect(find.textContaining('Premium'), findsNothing);

      await openTab(tester, Icons.person_outline);
      expect(find.text(english.profilePlanFreeTitle), findsOneWidget);
      expect(find.text(english.paywallTitle), findsNothing);

      await tapText(tester, english.paywallDiscover);

      expect(find.text(english.paywallTitle), findsOneWidget);
    });
  });

  group('écran d\'offres', () {
    testWidgets('présente annuel (mis en avant), mensuel puis hebdomadaire, '
        'avec prix, période, essai, renouvellement et annulation', (
      tester,
    ) async {
      await openPaywall(tester);

      expect(find.text(english.paywallTitle), findsOneWidget);
      double top(String plan) => tester.getTopLeft(find.text(plan)).dy;
      expect(top(english.planAnnual), lessThan(top(english.planMonthly)));
      expect(top(english.planMonthly), lessThan(top(english.planWeekly)));
      expect(find.text(english.paywallBestValue), findsOneWidget);
      expect(
        find.textContaining(english.pricePerYear(r'$29.99')),
        findsWidgets,
      );
      expect(
        find.textContaining(english.paywallAnnualEquivalent(r'$2.50')),
        findsOneWidget,
      );
      expect(find.text(english.paywallStartTrial(3)), findsOneWidget);
      expect(
        find.text(
          english.paywallTermsTrial(3, english.pricePerYear(r'$29.99')),
        ),
        findsOneWidget,
      );
      expect(find.text(english.paywallRestore), findsOneWidget);
      // Liens exigés par les stores pour un abonnement.
      expect(find.text(english.legalTermsTitle), findsOneWidget);
      expect(find.text(english.legalPrivacyTitle), findsOneWidget);
    });

    testWidgets('une offre sans essai change le bouton et les conditions', (
      tester,
    ) async {
      await openPaywall(tester);

      await tapText(tester, english.planWeekly);

      expect(find.text(english.paywallSubscribe), findsOneWidget);
      expect(
        find.text(english.paywallTerms(english.pricePerWeek(r'$2.99'))),
        findsOneWidget,
      );
    });

    testWidgets('la croix referme les offres sans rien acheter', (
      tester,
    ) async {
      await openPaywall(tester);

      await tapOn(tester, find.byType(CloseButton));

      expect(find.text(english.paywallTitle), findsNothing);
      expect(find.text(english.paywallDiscover), findsOneWidget);
      expect(billing.purchases, isEmpty);
    });

    testWidgets('sans store relié, l\'écran le dit au lieu de proposer un '
        'achat', (tester) async {
      billing.failure = const BillingUnavailableFailure();

      await openPaywall(tester);

      expect(find.text(english.errorBillingUnavailable), findsOneWidget);
      expect(find.text(english.paywallStartTrial(3)), findsNothing);
    });
  });

  group('achat', () {
    testWidgets('un achat réussi referme les offres et lève les limites', (
      tester,
    ) async {
      await openPaywall(tester);

      await tapText(tester, english.paywallStartTrial(3));

      expect(billing.purchases, [SubscriptionPlan.annual]);
      expect(find.text(english.paywallWelcome), findsOneWidget);
      expect(find.text(english.paywallTitle), findsNothing);
      // De nouveau un journal à écrire, avec la limite Premium.
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(english.journalSentenceCount(0, 40)), findsOneWidget);
    });

    testWidgets('l\'offre choisie est celle qui est achetée', (tester) async {
      await openPaywall(tester);

      await tapText(tester, english.planMonthly);
      await tapText(tester, english.paywallStartTrial(3));

      expect(billing.purchases, [SubscriptionPlan.monthly]);
    });

    testWidgets('refermer la fenêtre de paiement du store n\'affiche aucune '
        'erreur', (tester) async {
      billing.cancelsPurchase = true;
      await openPaywall(tester);

      await tapText(tester, english.paywallStartTrial(3));

      expect(find.text(english.paywallTitle), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(subscriptions.subscription, isNull);
    });

    testWidgets('un achat refusé par le store est expliqué, sans débit', (
      tester,
    ) async {
      await openPaywall(tester);
      billing.failure = const PurchaseFailure();

      await tapText(tester, english.paywallStartTrial(3));

      expect(find.text(english.errorPurchaseFailed), findsOneWidget);
      expect(find.text(english.paywallTitle), findsOneWidget);
    });

    testWidgets('une confirmation en retard active quand même Premium', (
      tester,
    ) async {
      billing.neverConfirms = true;
      await openPaywall(tester);
      subscriptions
        ..delayed = activeSubscription()
        ..readsBeforeDelayed = 2;

      // La confirmation arrive à la troisième lecture, 4 secondes après l'achat.
      await tapAndWait(
        tester,
        find.text(english.paywallStartTrial(3)),
        seconds: 5,
      );

      expect(find.text(english.paywallWelcome), findsOneWidget);
      expect(find.text(english.paywallTitle), findsNothing);
    });

    testWidgets('si la confirmation n\'arrive pas, l\'utilisateur sait que son '
        'achat est enregistré', (tester) async {
      billing.neverConfirms = true;
      await openPaywall(tester);

      // Cinq lectures espacées de 2 secondes avant d'abandonner.
      await tapAndWait(
        tester,
        find.text(english.paywallStartTrial(3)),
        seconds: 9,
      );

      expect(find.text(english.errorPurchasePending), findsOneWidget);
    });
  });

  group('restauration', () {
    /// Les offres, ouvertes depuis le profil.
    Future<void> openOffers(WidgetTester tester) async {
      await pump(tester);
      await openTab(tester, Icons.person_outline);
      await tapText(tester, english.paywallDiscover);
    }

    testWidgets('sans achat à retrouver, l\'utilisateur en est informé', (
      tester,
    ) async {
      await openOffers(tester);

      // Trois lectures espacées de 2 secondes avant de conclure.
      await tapAndWait(tester, find.text(english.paywallRestore), seconds: 5);

      expect(find.text(english.errorNothingToRestore), findsOneWidget);
      expect(find.text(english.paywallTitle), findsOneWidget);
    });

    testWidgets('un abonnement existant est retrouvé', (tester) async {
      billing.restorablePlan = SubscriptionPlan.monthly;
      await openOffers(tester);

      await tapAndWait(tester, find.text(english.paywallRestore), seconds: 1);
      // Les offres se referment sur le profil.
      await tester.pumpAndSettle();

      expect(find.text(english.paywallWelcome), findsOneWidget);
      expect(
        find.textContaining(english.profilePlanPremium(english.planMonthly)),
        findsOneWidget,
      );
    });
  });

  group('abonné', () {
    setUp(() => subscriptions.subscription = activeSubscription(inTrial: true));

    testWidgets(
      'le profil montre l\'offre, l\'échéance de l\'essai et ouvre la '
      'gestion de l\'abonnement dans le store',
      (tester) async {
        await pump(tester);
        await openTab(tester, Icons.person_outline);

        expect(
          find.textContaining(english.profilePlanPremium(english.planAnnual)),
          findsOneWidget,
        );
        expect(
          find.textContaining(english.profilePlanTrialUntil('Nov 19, 2027')),
          findsOneWidget,
        );

        await tapText(tester, english.profileManageSubscription);

        expect(openedUrls.single.host, 'play.google.com');
        expect(openedUrls.single.queryParameters['package'], isNotEmpty);
      },
    );

    testWidgets('le journal accepte jusqu\'à 40 phrases', (tester) async {
      await pump(tester);

      expect(find.text(english.journalSentenceCount(0, 40)), findsOneWidget);
    });

    testWidgets('à la limite du jour, aucun achat n\'est proposé', (
      tester,
    ) async {
      for (var index = 0; index < 30; index++) {
        journal.seedCorrectedToday(sampleEntry(id: 'entry-$index'));
      }
      await pump(tester);

      expect(find.text(english.journalPremiumLimitReached), findsOneWidget);
      expect(find.text(english.paywallDiscover), findsNothing);
    });

    testWidgets('tout l\'historique est lisible, rien n\'est verrouillé', (
      tester,
    ) async {
      journal
        ..seedPast(sampleEntry())
        ..lockedEntries = 3;
      await pump(tester);
      await openTab(tester, Icons.schedule_outlined);

      expect(find.text(english.historyUnlock), findsNothing);
    });
  });

  testWidgets(
    'des journaux verrouillés proposent Premium depuis l\'historique',
    (tester) async {
      journal
        ..seedPast(sampleEntry())
        ..lockedEntries = 3;
      await pump(tester);
      await openTab(tester, Icons.schedule_outlined);

      await tapText(tester, english.historyUnlock);

      expect(find.text(english.paywallTitle), findsOneWidget);
    },
  );

  testWidgets('un abonnement expiré ramène à l\'offre gratuite', (
    tester,
  ) async {
    subscriptions.subscription = Subscription(
      plan: SubscriptionPlan.monthly,
      expiresAt: testNow.subtract(const Duration(days: 1)),
    );
    await pump(tester);
    await openTab(tester, Icons.person_outline);

    expect(find.text(english.profilePlanFreeTitle), findsOneWidget);
    expect(find.text(english.profileManageSubscription), findsNothing);
  });
}
