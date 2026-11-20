import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/features/billing/domain/one_time_product.dart';
import 'package:journal_de_langue/features/billing/domain/wallet.dart';
import 'package:journal_de_langue/features/exam/domain/exam.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:journal_de_langue/shared/widgets/surfaces.dart';

import 'support/fakes.dart';
import 'support/pump_app.dart';

/// Achats à l'unité et simulation d'examen, sur des données en mémoire
/// (US-18 à 21).
void main() {
  late FakeAuthRepository auth;
  late FakeLanguageRepository languages;
  late FakeSubscriptionRepository subscriptions;
  late FakeWalletRepository wallet;
  late FakeBillingRepository billing;
  late FakeJournalRepository journal;
  late FakeExamRepository exams;

  setUp(() {
    auth = FakeAuthRepository(userId: FakeAuthRepository.signedInUserId);
    subscriptions = FakeSubscriptionRepository();
    languages = FakeLanguageRepository([
      LearningLanguage.english,
    ], subscriptions);
    wallet = FakeWalletRepository();
    billing = FakeBillingRepository(subscriptions, wallet);
    journal = FakeJournalRepository(
      subscriptions: subscriptions,
      wallet: wallet,
    );
    exams = FakeExamRepository(wallet);
  });

  /// Achat déjà possédé, dans la carte « Mes achats » de la boutique.
  Finder owned(String item) =>
      find.descendant(of: find.byType(HeroCard), matching: find.text(item));

  Future<void> pump(WidgetTester tester) => pumpApp(
    tester,
    auth: auth,
    languages: languages,
    journal: journal,
    subscriptions: subscriptions,
    billing: billing,
    wallet: wallet,
    exams: exams,
  );

  Future<void> tapText(WidgetTester tester, String text) =>
      tapOn(tester, find.text(text));

  Future<void> openTab(WidgetTester tester, IconData icon) =>
      tapOn(tester, find.byIcon(icon));

  /// Appuie sur [target] puis laisse passer [seconds] secondes d'attente de
  /// confirmation de l'achat.
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

  /// Remonte en haut de la boutique, où sont listés les achats.
  Future<void> scrollToTop(WidgetTester tester) async {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
  }

  /// Bouton d'achat d'un produit dans la boutique : il porte son prix.
  Finder buyButton(OneTimeProduct product) =>
      find.widgetWithText(FilledButton, FakeBillingRepository.priceOf(product));

  Future<void> correctTodaysJournal(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'I has a cat.');
    await tester.pump();
    await tapOn(
      tester,
      find.widgetWithText(FilledButton, english.journalSubmit),
    );
    await tapText(tester, english.correctionDone);
  }

  group('corrections à l\'unité', () {
    testWidgets('à la limite du jour, la boutique est proposée ; 10 '
        'corrections achetées rouvrent le journal', (tester) async {
      await pump(tester);
      await correctTodaysJournal(tester);

      await tapText(tester, english.journalBuyCorrections);

      expect(find.text(english.shopTitle), findsOneWidget);
      expect(find.text(english.shopNothingOwned), findsOneWidget);
      expect(find.text(english.productCorrections10), findsOneWidget);
      expect(find.text(english.productExamPack), findsWidgets);
      expect(find.text(english.shopLanguagePassTitle), findsOneWidget);

      await tapAndWait(
        tester,
        buyButton(OneTimeProduct.corrections10),
        seconds: 3,
      );

      expect(billing.boughtProducts, [OneTimeProduct.corrections10]);
      expect(find.text(english.shopPurchased), findsOneWidget);
      await scrollToTop(tester);
      expect(owned(english.shopCredits(10)), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(english.journalUsesCredit(10)), findsOneWidget);
    });

    testWidgets('une correction payée par un crédit en débite un seul', (
      tester,
    ) async {
      wallet.wallet = const Wallet(correctionCredits: 2);
      journal.seedCorrectedToday(sampleEntry(id: 'today'));
      await pump(tester);

      expect(find.text(english.journalUsesCredit(2)), findsOneWidget);

      await correctTodaysJournal(tester);

      expect(wallet.wallet.correctionCredits, 1);
      expect(find.text(english.journalUsesCredit(1)), findsOneWidget);
    });

    testWidgets('sans store relié, la boutique le dit et garde les achats '
        'visibles', (tester) async {
      wallet.wallet = const Wallet(correctionCredits: 3);
      billing.failure = const BillingUnavailableFailure();
      journal.seedPast(sampleEntry());
      await pump(tester);
      await openTab(tester, Icons.person_outline);

      await tapText(tester, english.profilePurchases);

      expect(find.text(english.errorBillingUnavailable), findsOneWidget);
      expect(owned(english.shopCredits(3)), findsOneWidget);
    });

    testWidgets('refermer la fenêtre de paiement n\'achète rien', (
      tester,
    ) async {
      billing.cancelsPurchase = true;
      journal.seedPast(sampleEntry());
      await pump(tester);
      await openTab(tester, Icons.person_outline);
      await tapText(tester, english.profilePurchases);

      await tapAndWait(tester, buyButton(OneTimeProduct.examPack), seconds: 1);

      expect(find.text(english.shopPurchased), findsNothing);
      expect(wallet.wallet, const Wallet());
    });

    testWidgets('si la confirmation n\'arrive pas, l\'achat est dit '
        'enregistré', (tester) async {
      billing.neverConfirms = true;
      journal.seedPast(sampleEntry());
      await pump(tester);
      await openTab(tester, Icons.person_outline);
      await tapText(tester, english.profilePurchases);

      await tapAndWait(
        tester,
        buyButton(OneTimeProduct.corrections50),
        seconds: 11,
      );

      expect(find.text(english.errorPurchasePending), findsOneWidget);
    });
  });

  group('accès langue et sans publicité', () {
    testWidgets('un accès de 30 jours et « sans publicité » apparaissent dans '
        'les achats', (tester) async {
      journal.seedPast(sampleEntry());
      await pump(tester);
      await openTab(tester, Icons.person_outline);
      await tapText(tester, english.profilePurchases);

      await tapAndWait(
        tester,
        find.descendant(
          of: find.widgetWithText(ListTile, english.languageSpanish),
          matching: find.byType(FilledButton),
        ),
        seconds: 3,
      );
      await tapAndWait(tester, buyButton(OneTimeProduct.removeAds), seconds: 3);
      await scrollToTop(tester);

      expect(
        owned(english.shopPassUntil(english.languageSpanish, 'Dec 19, 2026')),
        findsOneWidget,
      );
      expect(owned(english.shopAdsRemoved), findsOneWidget);
      // Déjà acheté : « sans publicité » n'est plus proposé.
      expect(find.text(english.shopRemoveAdsBody), findsNothing);
    });

    testWidgets('dès le premier jour, le profil mène aux achats et à leur '
        'restauration', (tester) async {
      await pump(tester);
      await openTab(tester, Icons.person_outline);

      await tapText(tester, english.profilePurchases);

      expect(find.text(english.shopTitle), findsOneWidget);
      await tester.scrollUntilVisible(find.text(english.paywallRestore), 300);
      expect(find.text(english.paywallRestore), findsOneWidget);
    });

    testWidgets('« sans publicité » acheté avec le même compte du store est '
        'restauré depuis les achats', (tester) async {
      billing.restorableProducts.add(OneTimeProduct.removeAds);
      await pump(tester);
      await openTab(tester, Icons.person_outline);
      await tapText(tester, english.profilePurchases);

      await tester.scrollUntilVisible(find.text(english.paywallRestore), 300);
      await tapText(tester, english.paywallRestore);

      expect(find.text(english.shopRestored), findsOneWidget);
      await scrollToTop(tester);
      expect(owned(english.shopAdsRemoved), findsOneWidget);
    });
  });

  group('simulation d\'examen', () {
    Future<void> openExam(WidgetTester tester) async {
      await openTab(tester, Icons.copy_outlined);
      await tapText(tester, english.examTitle);
    }

    testWidgets('avant la première correction et sans pack, la simulation '
        's\'explique sans proposer la boutique', (tester) async {
      await pump(tester);
      await openExam(tester);

      expect(find.text(english.examNoCredit), findsOneWidget);
      expect(find.text(english.examBuyPack), findsNothing);
    });

    testWidgets('sans pack : explication et accès à la boutique', (
      tester,
    ) async {
      journal.seedPast(sampleEntry());
      await pump(tester);
      await openExam(tester);

      expect(find.text(english.examNoCredit), findsOneWidget);

      await tapText(tester, english.examBuyPack);

      expect(find.text(english.shopTitle), findsOneWidget);
    });

    testWidgets('un pack : choix du niveau, sujet, copie notée, critères et '
        'plan de révision', (tester) async {
      wallet.wallet = const Wallet(examCredits: 1);
      await pump(tester);
      await openExam(tester);

      expect(find.text(english.examCreditsLeft(1)), findsOneWidget);

      await tapText(tester, 'C1');
      await tapText(tester, english.examStart);

      expect(exams.exams.single.level, ExamLevel.c1);
      expect(wallet.wallet.examCredits, 0);
      expect(find.text(sampleExamPrompt.title), findsOneWidget);
      expect(find.text(sampleExamPrompt.task), findsOneWidget);
      expect(find.text(english.examWordTarget(120, 180)), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        'Last summer I goed to Rome.',
      );
      await tester.pump();

      expect(find.text(english.examWordCount(6)), findsOneWidget);

      // Le brouillon est enregistré pendant la saisie.
      await tester.pump(const Duration(seconds: 3));
      expect(exams.drafts.last, 'Last summer I goed to Rome.');

      await tapText(tester, english.examSubmit);

      expect(find.text(english.examScore(14)), findsOneWidget);
      expect(find.text(english.examLevelEstimate('B1')), findsOneWidget);
      expect(find.text(english.criterionGrammar), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Irregular verbs'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('"Go" is irregular.'), findsOneWidget);
      expect(find.text('Irregular verbs'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text(english.examResultsTitle), findsOneWidget);
      expect(find.text(english.examNoCredit), findsOneWidget);
    });

    testWidgets('une simulation interrompue reprend avec le texte déjà écrit', (
      tester,
    ) async {
      exams.exams.add(
        Exam(
          id: 'exam-open',
          language: LearningLanguage.english,
          level: ExamLevel.b1,
          status: ExamStatus.inProgress,
          createdAt: DateTime(2026, 11, 18),
          prompt: sampleExamPrompt,
          answer: 'Dear Sam,',
        ),
      );
      journal.seedPast(sampleEntry());
      await pump(tester);
      await openExam(tester);

      expect(find.text(english.examResumeNote), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Dear Sam,',
      );
    });

    testWidgets('quitter la simulation envoie le dernier texte écrit', (
      tester,
    ) async {
      exams.exams.add(
        Exam(
          id: 'exam-open',
          language: LearningLanguage.english,
          level: ExamLevel.b1,
          status: ExamStatus.inProgress,
          createdAt: DateTime(2026, 11, 18),
          prompt: sampleExamPrompt,
          answer: 'Dear Sam,',
        ),
      );
      await pump(tester);
      await openExam(tester);

      await tester.enterText(find.byType(TextField), 'Dear Sam, I am fine.');
      await tester.pump();
      // Retour avant l'enregistrement automatique, qui attend 2 secondes.
      await tapOn(tester, find.byType(BackButton));

      expect(exams.drafts, ['Dear Sam, I am fine.']);
    });

    testWidgets('une copie en cours de notation ne se modifie plus', (
      tester,
    ) async {
      exams.exams.add(
        Exam(
          id: 'exam-grading',
          language: LearningLanguage.english,
          level: ExamLevel.b1,
          status: ExamStatus.grading,
          createdAt: DateTime(2026, 11, 18),
          prompt: sampleExamPrompt,
          answer: 'Dear Sam,',
        ),
      );
      await pump(tester);
      await openExam(tester);

      expect(find.text(english.examGrading), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('des achats illisibles ne passent pas pour « rien acheté »', (
      tester,
    ) async {
      wallet.failure = const NetworkFailure();
      await pump(tester);
      await openTab(tester, Icons.person_outline);
      await tapText(tester, english.profilePurchases);

      expect(find.text(english.shopNothingOwned), findsNothing);
      expect(find.text(english.errorNetwork), findsOneWidget);
      expect(find.text(english.shopRemoveAdsBody), findsNothing);
    });

    testWidgets('un sujet qui n\'a pas pu être créé est expliqué', (
      tester,
    ) async {
      wallet.wallet = const Wallet(examCredits: 1);
      exams.startFailure = const AiUnavailableFailure();
      await pump(tester);
      await openExam(tester);

      await tapText(tester, english.examStart);

      expect(find.text(english.errorAiUnavailable), findsOneWidget);
      expect(find.text(english.examStart), findsOneWidget);
    });
  });
}
