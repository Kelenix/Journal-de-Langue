import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:journal_de_langue/features/vocabulary/domain/vocabulary_item.dart';

import 'support/fakes.dart';
import 'support/pump_app.dart';

/// Vocabulaire à réviser et historique, sur des données en mémoire
/// (US-08, US-09).
void main() {
  const secondWord = VocabularyItem(
    id: 'word-2',
    term: 'to sleep',
    translation: 'dormir',
    example: 'I sleep eight hours.',
  );

  late FakeAuthRepository auth;
  late FakeLanguageRepository languages;
  late FakeVocabularyRepository vocabulary;
  late FakeJournalRepository journal;

  setUp(() {
    auth = FakeAuthRepository(userId: FakeAuthRepository.signedInUserId);
    languages = FakeLanguageRepository([LearningLanguage.english]);
    vocabulary = FakeVocabularyRepository();
    journal = FakeJournalRepository(vocabulary: vocabulary);
  });

  Future<void> pump(WidgetTester tester) => pumpApp(
    tester,
    auth: auth,
    languages: languages,
    journal: journal,
    vocabulary: vocabulary,
  );

  Future<void> openTab(WidgetTester tester, IconData icon) =>
      tapOn(tester, find.byIcon(icon));

  Future<void> openReview(WidgetTester tester) =>
      openTab(tester, Icons.style_outlined);

  Future<void> openHistory(WidgetTester tester) =>
      openTab(tester, Icons.history_outlined);

  group('Réviser', () {
    testWidgets('sans journal corrigé, l\'écran explique comment obtenir des '
        'mots', (tester) async {
      await pump(tester);
      await openReview(tester);

      expect(find.text(english.reviewEmpty), findsOneWidget);
    });

    testWidgets('chaque mot montre sa traduction et un exemple', (
      tester,
    ) async {
      vocabulary.items.add(sampleWord);
      await pump(tester);
      await openReview(tester);

      expect(find.text('a cat'), findsOneWidget);
      expect(find.text('un chat'), findsOneWidget);
      expect(find.text('The cat is sleeping.'), findsOneWidget);
      expect(find.text(english.reviewLearnedCount(0)), findsOneWidget);
    });

    testWidgets('marquer un mot comme appris le compte et se défait', (
      tester,
    ) async {
      vocabulary.items.addAll([sampleWord, secondWord]);
      await pump(tester);
      await openReview(tester);

      await tapOn(tester, find.byTooltip(english.reviewMarkLearned).first);

      expect(find.text(english.reviewLearnedCount(1)), findsOneWidget);
      expect(vocabulary.items.first.learnedAt, isNotNull);
      // Le mot appris passe après celui qui reste à réviser.
      expect(
        tester.getTopLeft(find.text('to sleep')).dy,
        lessThan(tester.getTopLeft(find.text('a cat')).dy),
      );

      await tapOn(tester, find.byTooltip(english.reviewMarkToReview));

      expect(find.text(english.reviewLearnedCount(0)), findsOneWidget);
      expect(vocabulary.items.first.learnedAt, isNull);
    });

    testWidgets('si l\'enregistrement échoue, le mot reste à réviser et '
        'l\'utilisateur est prévenu', (tester) async {
      vocabulary.items.add(sampleWord);
      await pump(tester);
      await openReview(tester);
      vocabulary.failure = const NetworkFailure();

      await tapOn(tester, find.byTooltip(english.reviewMarkLearned));

      expect(find.text(english.errorNetwork), findsOneWidget);
      expect(find.text(english.reviewLearnedCount(0)), findsOneWidget);
    });

    testWidgets('un vocabulaire qui ne se charge pas propose de réessayer', (
      tester,
    ) async {
      vocabulary
        ..items.add(sampleWord)
        ..failure = const NetworkFailure();
      await pump(tester);
      await openReview(tester);

      expect(find.text(english.errorNetwork), findsOneWidget);

      vocabulary.failure = null;
      await tapOn(tester, find.text(english.actionRetry));

      expect(find.text('a cat'), findsOneWidget);
    });
  });

  group('après une correction', () {
    Future<void> correctJournal(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField), 'I has a cat.');
      await tester.pump();
      await tapOn(
        tester,
        find.widgetWithText(FilledButton, english.journalSubmit),
      );
    }

    testWidgets('la correction propose ses mots à réviser', (tester) async {
      await pump(tester);

      await correctJournal(tester);

      await tester.ensureVisible(find.text('a cat'));
      expect(find.text(english.correctionVocabularyTitle), findsOneWidget);
      expect(find.text('un chat'), findsOneWidget);
    });

    testWidgets('les mots et le journal apparaissent dans Réviser et '
        'Historique', (tester) async {
      await pump(tester);
      await openReview(tester);
      expect(find.text(english.reviewEmpty), findsOneWidget);
      await openHistory(tester);
      expect(find.text(english.historyEmpty), findsOneWidget);

      await openTab(tester, Icons.edit_note_outlined);
      await correctJournal(tester);
      await tapOn(tester, find.text(english.correctionDone));

      await openReview(tester);
      expect(find.text('a cat'), findsOneWidget);

      await openHistory(tester);
      expect(find.text('I has a cat.'), findsOneWidget);
      expect(find.text(english.historyMistakes(1)), findsOneWidget);
    });
  });

  group('Historique', () {
    testWidgets('sans journal, l\'écran dit où ils apparaîtront', (
      tester,
    ) async {
      await pump(tester);
      await openHistory(tester);

      expect(find.text(english.historyEmpty), findsOneWidget);
    });

    testWidgets('les journaux sont listés du plus récent au plus ancien et '
        'ouvrent leur correction', (tester) async {
      journal
        ..seedPast(
          sampleEntry(
            id: 'old',
            originalText: 'Older entry.',
            entryDate: DateTime(2026, 11, 17),
          ),
        )
        ..seedPast(
          sampleEntry(
            id: 'new',
            originalText: 'Newer entry.',
            entryDate: DateTime(2026, 11, 18),
          ),
        );
      await pump(tester);
      await openHistory(tester);

      expect(
        tester.getTopLeft(find.text('Newer entry.')).dy,
        lessThan(tester.getTopLeft(find.text('Older entry.')).dy),
      );

      await tapOn(tester, find.text('Older entry.'));

      expect(find.text(english.correctionYourVersion), findsOneWidget);
    });

    testWidgets('les journaux plus anciens sont signalés comme conservés', (
      tester,
    ) async {
      journal
        ..seedPast(sampleEntry())
        ..lockedEntries = 3;
      await pump(tester);
      await openHistory(tester);

      expect(
        find.text('${english.historyLocked(3)} ${english.historyWindow(4)}'),
        findsOneWidget,
      );
    });

    testWidgets('un historique entièrement verrouillé n\'affiche pas l\'état '
        'vide', (tester) async {
      journal.lockedEntries = 2;
      await pump(tester);
      await openHistory(tester);

      expect(find.text(english.historyEmpty), findsNothing);
      expect(find.textContaining(english.historyLocked(2)), findsOneWidget);
    });

    testWidgets('un historique qui ne se charge pas propose de réessayer', (
      tester,
    ) async {
      journal.seedPast(sampleEntry());
      await pump(tester);
      journal.loadFailure = const NetworkFailure();
      await openHistory(tester);

      expect(find.text(english.errorNetwork), findsWidgets);
    });
  });
}
