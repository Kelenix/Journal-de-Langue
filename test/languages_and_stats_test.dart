import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/features/billing/domain/subscription.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';

import 'support/fakes.dart';
import 'support/pump_app.dart';

/// Langues selon l'offre et statistiques, sur des données en mémoire
/// (US-04, US-16).
void main() {
  late FakeAuthRepository auth;
  late FakeSubscriptionRepository subscriptions;
  late FakeLanguageRepository languages;
  late FakeJournalRepository journal;
  late FakeStatsRepository stats;

  setUp(() {
    auth = FakeAuthRepository(userId: FakeAuthRepository.signedInUserId);
    subscriptions = FakeSubscriptionRepository();
    languages = FakeLanguageRepository([
      LearningLanguage.english,
    ], subscriptions);
    journal = FakeJournalRepository(subscriptions: subscriptions);
    stats = FakeStatsRepository(journal: journal, subscriptions: subscriptions);
  });

  void subscribe(SubscriptionPlan plan) => subscriptions.subscription =
      Subscription(plan: plan, expiresAt: FakeSubscriptionRepository.farFuture);

  Future<void> pump(WidgetTester tester) => pumpApp(
    tester,
    auth: auth,
    languages: languages,
    journal: journal,
    subscriptions: subscriptions,
    stats: stats,
  );

  Future<void> tapText(WidgetTester tester, String text) =>
      tapOn(tester, find.text(text));

  Future<void> openTab(WidgetTester tester, IconData icon) =>
      tapOn(tester, find.byIcon(icon));

  Future<void> openLanguages(WidgetTester tester, {int count = 1}) async {
    await openTab(tester, Icons.person_outline);
    await tapText(tester, english.profileLanguages(count));
  }

  /// Ligne d'une langue dans la feuille de gestion des langues.
  Finder languageRow(String name) => find.widgetWithText(ListTile, name);

  group('langues, gratuit', () {
    testWidgets('une seule langue : la puce du journal ne propose pas d\'en '
        'changer, et aucune offre avant une première correction', (
      tester,
    ) async {
      await pump(tester);

      expect(find.byTooltip(english.journalSwitchLanguage), findsNothing);

      await openLanguages(tester);

      expect(find.text(english.profileChangeLanguageNote), findsOneWidget);
      expect(find.text(english.languagesPremiumHint), findsNothing);
    });

    testWidgets('après une première correction, plusieurs langues sont '
        'proposées avec Premium', (tester) async {
      journal.seedPast(sampleEntry());
      await pump(tester);
      await openLanguages(tester);

      await tapText(tester, english.languagesPremiumHint);

      expect(find.text(english.paywallTitle), findsOneWidget);
      expect(find.text(english.paywallBenefitLanguages), findsOneWidget);
    });
  });

  group('langues, Premium', () {
    testWidgets('ajouter une langue la rend langue du journal ; la puce permet '
        'de revenir à l\'autre', (tester) async {
      subscribe(SubscriptionPlan.monthly);
      await pump(tester);
      await openLanguages(tester);

      expect(find.text(english.profileLanguagesPremiumNote), findsOneWidget);

      await tapOn(tester, languageRow(english.languageSpanish));

      expect(await languages.activeLanguages(), [
        LearningLanguage.spanish,
        LearningLanguage.english,
      ]);
      expect(
        find.descendant(
          of: languageRow(english.languageSpanish),
          matching: find.text(english.languageCurrent),
        ),
        findsOneWidget,
      );

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(
        find.text('${english.languageSpanish}, ${english.languageEnglish}'),
        findsOneWidget,
      );

      await openTab(tester, Icons.edit_note_outlined);
      await tapOn(tester, find.byTooltip(english.journalSwitchLanguage));
      await tapOn(
        tester,
        find.widgetWithText(
          PopupMenuItem<LearningLanguage>,
          english.languageEnglish,
        ),
      );

      expect(await languages.activeLanguages(), [
        LearningLanguage.english,
        LearningLanguage.spanish,
      ]);
    });

    testWidgets('mensuel : une quatrième langue est refusée avec une '
        'explication', (tester) async {
      subscribe(SubscriptionPlan.monthly);
      await languages.activate(LearningLanguage.spanish);
      await languages.activate(LearningLanguage.german);
      await pump(tester);
      await openLanguages(tester, count: 3);

      await tapOn(tester, languageRow(english.languageFrench));

      expect(find.text(english.errorLanguageLimit), findsOneWidget);
      expect(await languages.activeLanguages(), hasLength(3));
    });

    testWidgets('annuel : les quatre langues', (tester) async {
      subscribe(SubscriptionPlan.annual);
      await languages.activate(LearningLanguage.spanish);
      await languages.activate(LearningLanguage.german);
      await pump(tester);
      await openLanguages(tester, count: 3);

      await tapOn(tester, languageRow(english.languageFrench));

      expect(find.text(english.errorLanguageLimit), findsNothing);
      expect(await languages.activeLanguages(), hasLength(4));
    });

    testWidgets('retirer une langue ; la dernière ne peut pas l\'être', (
      tester,
    ) async {
      subscribe(SubscriptionPlan.monthly);
      await languages.activate(LearningLanguage.spanish);
      await pump(tester);
      await openLanguages(tester, count: 2);

      expect(find.byTooltip(english.languageRemove), findsNWidgets(2));

      await tapOn(
        tester,
        find.descendant(
          of: languageRow(english.languageEnglish),
          matching: find.byTooltip(english.languageRemove),
        ),
      );

      expect(await languages.activeLanguages(), [LearningLanguage.spanish]);
      expect(find.byTooltip(english.languageRemove), findsNothing);
    });

    testWidgets('abonnement terminé : seule la langue en cours reste', (
      tester,
    ) async {
      subscribe(SubscriptionPlan.monthly);
      await languages.activate(LearningLanguage.spanish);
      subscriptions.subscription = null;

      await pump(tester);
      await openTab(tester, Icons.person_outline);

      expect(find.text(english.profileLanguages(1)), findsOneWidget);
      expect(find.text(english.languageSpanish), findsOneWidget);
    });
  });

  group('statistiques', () {
    Future<void> openProgress(WidgetTester tester) async {
      await pump(tester);
      await openTab(tester, Icons.local_fire_department_outlined);
    }

    testWidgets('sans journal, l\'écran dit quand la série commencera', (
      tester,
    ) async {
      await openProgress(tester);

      expect(find.text(english.progressEmpty), findsOneWidget);
    });

    testWidgets('gratuit : la série et les journaux, le reste avec Premium', (
      tester,
    ) async {
      journal
        ..seedPast(sampleEntry(id: 'today'))
        ..seedPast(
          sampleEntry(id: 'yesterday', entryDate: DateTime(2026, 11, 18)),
        )
        ..seedPast(sampleEntry(id: 'old', entryDate: DateTime(2026, 11, 10)));

      await openProgress(tester);

      expect(find.text(english.progressStreakLabel), findsOneWidget);
      // Le chiffre et son unité forment un seul texte.
      expect(find.text('2 ${english.progressStreakUnit(2)}'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text(english.progressMistakesTitle), findsNothing);

      await tapText(tester, english.paywallDiscover);

      expect(find.text(english.paywallTitle), findsOneWidget);
    });

    testWidgets('Premium : mots appris, fautes par type et par semaine', (
      tester,
    ) async {
      subscribe(SubscriptionPlan.monthly);
      journal.seedPast(sampleEntry());

      await openProgress(tester);

      expect(find.text(english.progressWordsLearned), findsOneWidget);
      expect(find.text(english.progressWordsOf(1)), findsOneWidget);
      expect(find.text(english.categoryConjugation), findsOneWidget);
      expect(find.text(english.progressPremiumTitle), findsNothing);
      expect(find.text(english.progressJournals), findsOneWidget);
      // L'axe couvre toujours 8 semaines, même sans journal les premières.
      expect(find.text('Sep 28'), findsOneWidget);
      expect(find.text('Nov 16'), findsOneWidget);

      await tapText(tester, english.progressRateDetails);

      expect(
        find.text(english.progressRateWeek('Nov 16', '0.50')),
        findsWidgets,
      );
    });

    testWidgets('des statistiques qui ne se chargent pas proposent de '
        'réessayer', (tester) async {
      stats.failure = const NetworkFailure();
      await openProgress(tester);

      expect(find.text(english.errorNetwork), findsOneWidget);

      stats.failure = null;
      await tapText(tester, english.actionRetry);

      expect(find.text(english.progressEmpty), findsOneWidget);
    });

    testWidgets('la série s\'affiche sur le journal et grandit avec la '
        'correction du jour', (tester) async {
      journal.seedPast(
        sampleEntry(id: 'yesterday', entryDate: DateTime(2026, 11, 18)),
      );
      await pump(tester);

      expect(find.text(english.journalStreak(1)), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'I has a cat.');
      await tester.pump();
      await tapOn(
        tester,
        find.widgetWithText(FilledButton, english.journalSubmit),
      );
      await tapText(tester, english.correctionDone);

      expect(find.text(english.journalStreak(2)), findsOneWidget);
    });
  });
}
