import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';

import 'support/fakes.dart';
import 'support/pump_app.dart';

/// Journal du jour et correction, sur des données en mémoire (US-05 à US-07).
void main() {
  const userId = FakeAuthRepository.signedInUserId;
  const draftKey = (userId, LearningLanguage.english);

  late FakeAuthRepository auth;
  late FakeLanguageRepository languages;
  late FakeJournalRepository journal;
  late InMemoryJournalDraftStore drafts;

  setUp(() {
    auth = FakeAuthRepository(userId: userId);
    languages = FakeLanguageRepository([LearningLanguage.english]);
    journal = FakeJournalRepository();
    drafts = InMemoryJournalDraftStore();
  });

  Future<void> pumpJournal(WidgetTester tester) => pumpApp(
    tester,
    auth: auth,
    languages: languages,
    journal: journal,
    drafts: drafts,
  );

  Future<void> write(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
  }

  Future<void> tapSubmit(WidgetTester tester) =>
      tapOn(tester, find.widgetWithText(FilledButton, english.journalSubmit));

  Future<void> tapText(WidgetTester tester, String text) =>
      tapOn(tester, find.text(text));

  testWidgets('le compteur suit le nombre de phrases écrites', (tester) async {
    await pumpJournal(tester);
    expect(find.text(english.journalSentenceCount(0, 7)), findsOneWidget);

    await write(tester, 'I went out. It was cold!');

    expect(find.text(english.journalSentenceCount(2, 7)), findsOneWidget);
  });

  testWidgets(
    'au-delà de 7 phrases, l\'envoi est bloqué avec une explication',
    (tester) async {
      await pumpJournal(tester);

      await write(tester, 'A. B. C. D. E. F. G. H.');
      await tapSubmit(tester);

      expect(find.text(english.journalTooManySentences(7)), findsOneWidget);
      expect(journal.submissions, isEmpty);
    },
  );

  testWidgets('un journal vide ne peut pas être envoyé', (tester) async {
    await pumpJournal(tester);

    await tapSubmit(tester);

    expect(journal.submissions, isEmpty);
  });

  testWidgets(
    'un journal envoyé affiche sa correction puis la limite du jour',
    (tester) async {
      await pumpJournal(tester);

      await write(tester, 'I has a cat.');
      await tapSubmit(tester);

      expect(find.text(english.correctionYourVersion), findsOneWidget);
      expect(find.text(english.correctionPointsTitle(1)), findsOneWidget);
      expect(find.text('With "I", use "have".'), findsOneWidget);
      expect(journal.submissions.single.text, 'I has a cat.');

      await tapText(tester, english.correctionDone);

      expect(find.text(english.journalDailyLimitReached), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tapText(tester, english.journalViewCorrection);

      expect(find.text('With "I", use "have".'), findsOneWidget);
    },
  );

  testWidgets('aucune offre payante n\'apparaît avant la première correction ; '
      'elle est proposée une fois la limite du jour atteinte', (tester) async {
    await pumpJournal(tester);
    expect(find.textContaining('Premium'), findsNothing);

    await write(tester, 'I has a cat.');
    await tapSubmit(tester);
    expect(find.textContaining('Premium'), findsNothing);

    await tapText(tester, english.correctionDone);

    expect(find.text(english.journalDailyLimitReached), findsOneWidget);
    expect(find.text(english.paywallDiscover), findsOneWidget);
  });

  testWidgets('une panne de correction garde le texte et dit que rien n\'est '
      'débité ; le nouvel essai rejoue le même envoi', (tester) async {
    journal.submitFailure = const AiUnavailableFailure();
    await pumpJournal(tester);

    await write(tester, 'I has a cat.');
    await tapSubmit(tester);

    expect(find.text(english.errorAiUnavailable), findsOneWidget);
    expect(find.text('I has a cat.'), findsOneWidget);

    journal.submitFailure = null;
    await tapSubmit(tester);

    expect(find.text(english.correctionYourVersion), findsOneWidget);
    expect(journal.submissions, hasLength(2));
    expect(
      journal.submissions[1].idempotencyKey,
      journal.submissions[0].idempotencyKey,
    );
  });

  testWidgets('un texte modifié après un échec est un nouvel envoi', (
    tester,
  ) async {
    journal.submitFailure = const NetworkFailure();
    await pumpJournal(tester);

    await write(tester, 'I has a cat.');
    await tapSubmit(tester);
    expect(find.text(english.errorNetwork), findsOneWidget);

    await write(tester, 'I has a dog.');
    await tapSubmit(tester);

    expect(
      journal.submissions[1].idempotencyKey,
      isNot(journal.submissions[0].idempotencyKey),
    );
  });

  testWidgets('un refus du serveur est expliqué', (tester) async {
    journal.submitFailure = const CorrectionDeniedFailure(
      CorrectionDenial.wrongLanguage,
    );
    await pumpJournal(tester);

    await write(tester, 'Bonjour tout le monde.');
    await tapSubmit(tester);

    expect(find.text(english.errorWrongLanguage), findsOneWidget);
  });

  testWidgets('la correction du jour déjà faite : rappel et accès direct', (
    tester,
  ) async {
    journal.seedCorrectedToday(sampleEntry());
    await pumpJournal(tester);

    expect(find.text(english.journalDailyLimitReached), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tapText(tester, english.journalViewCorrection);

    expect(find.text(english.correctionCorrectedVersion), findsOneWidget);
  });

  testWidgets(
    'le lendemain, l\'app restée ouverte propose un nouveau journal',
    (tester) async {
      var now = testNow;
      journal.seedCorrectedToday(sampleEntry());
      await pumpApp(
        tester,
        auth: auth,
        languages: languages,
        journal: journal,
        drafts: drafts,
        clock: () => now,
      );
      expect(find.text(english.journalDailyLimitReached), findsOneWidget);

      now = testNow.add(const Duration(days: 1));
      journal.startNewDay();
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    },
  );

  testWidgets('un brouillon plus long que la limite de l\'offre ne part pas', (
    tester,
  ) async {
    // Compté comme sur le serveur : « é » vaut un caractère, le point aussi.
    drafts.drafts[draftKey] = '${'a' * 1000}é.';
    await pumpJournal(tester);

    expect(find.text('1002 / 1000'), findsOneWidget);
    await tapSubmit(tester);
    expect(journal.submissions, isEmpty);
  });

  testWidgets('quota utilisé depuis un autre appareil : le refus mène à la '
      'correction du jour', (tester) async {
    await pumpJournal(tester);
    await write(tester, 'I has a cat.');
    journal
      ..seedCorrectedToday(sampleEntry())
      ..submitFailure = const CorrectionDeniedFailure(
        CorrectionDenial.dailyLimit,
      );

    await tapSubmit(tester);

    expect(find.text(english.journalViewCorrection), findsOneWidget);
  });

  testWidgets('un journal sans faute est salué', (tester) async {
    journal.seedCorrectedToday(
      sampleEntry(originalText: 'I have a cat.').copyWith(items: const []),
    );
    await pumpJournal(tester);

    await tapText(tester, english.journalViewCorrection);

    expect(find.text(english.correctionNoMistakes), findsOneWidget);
  });

  testWidgets('« Ta version » montre le texte envoyé, la version corrigée '
      'est affichée d\'abord', (tester) async {
    journal.seedCorrectedToday(sampleEntry());
    await pumpJournal(tester);
    await tapText(tester, english.journalViewCorrection);
    expect(find.text('I has a cat.'), findsNothing);

    await tapText(tester, english.correctionYourVersion);

    expect(find.text('I has a cat.'), findsOneWidget);
  });

  testWidgets('le brouillon est retrouvé à l\'ouverture', (tester) async {
    drafts.drafts[draftKey] = 'Yesterday I';
    await pumpJournal(tester);

    expect(find.text('Yesterday I'), findsOneWidget);
  });

  testWidgets('le brouillon est enregistré pendant la saisie, puis effacé une '
      'fois le journal corrigé', (tester) async {
    await pumpJournal(tester);

    await write(tester, 'Today I');
    await tester.pump(const Duration(seconds: 1));
    expect(drafts.drafts[draftKey], 'Today I');

    await write(tester, 'Today I has a cat.');
    await tapSubmit(tester);
    await tapText(tester, english.correctionDone);

    expect(drafts.drafts[draftKey], isEmpty);
  });

  testWidgets('un journal qui ne se charge pas propose de réessayer', (
    tester,
  ) async {
    journal.loadFailure = const NetworkFailure();
    await pumpJournal(tester);

    expect(find.text(english.errorNetwork), findsOneWidget);

    journal.loadFailure = null;
    await tapText(tester, english.actionRetry);

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets(
    'supprimer son compte efface aussi les brouillons de l\'appareil',
    (tester) async {
      drafts.drafts[draftKey] = 'Private thoughts';
      await pumpJournal(tester);

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      await tapText(tester, english.profileDeleteAccount);
      await tapText(tester, english.actionContinue);
      await tapText(tester, english.deleteAccountConfirm);

      expect(drafts.drafts, isEmpty);
    },
  );
}
