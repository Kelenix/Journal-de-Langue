import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:journal_de_langue/features/vocabulary/domain/vocabulary_item.dart';
import 'package:journal_de_langue/features/vocabulary/presentation/daily_card.dart';

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

      final row = wordRow(sampleWord.id);
      await tester.scrollUntilVisible(row, 200);
      for (final text in ['a cat', 'un chat', 'The cat is sleeping.']) {
        expect(find.descendant(of: row, matching: find.text(text)), findsOne);
      }
      expect(find.text(english.reviewLearnedCount(0)), findsOneWidget);
    });

    testWidgets('marquer un mot comme appris le compte et se défait', (
      tester,
    ) async {
      vocabulary.items.addAll([sampleWord, secondWord]);
      await pump(tester);
      await openReview(tester);

      await tester.scrollUntilVisible(wordRow(secondWord.id), 200);
      await tapOn(tester, find.byTooltip(english.reviewMarkLearned).first);

      expect(find.text(english.reviewLearnedCount(1)), findsOneWidget);
      expect(vocabulary.items.first.learnedAt, isNotNull);
      // Le mot appris passe après celui qui reste à réviser.
      expect(
        tester.getTopLeft(wordRow(secondWord.id)).dy,
        lessThan(tester.getTopLeft(wordRow(sampleWord.id)).dy),
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

      expect(find.text(english.reviewWordsTitle), findsOneWidget);
    });

    group('carte du jour', () {
      Finder onCard(String text) => find.descendant(
        of: find.byType(DailyCard),
        matching: find.text(text),
      );

      testWidgets('un mot à réviser à la fois, la traduction à la demande', (
        tester,
      ) async {
        vocabulary.items.addAll([sampleWord, secondWord]);
        await pump(tester);
        await openReview(tester);

        expect(find.text(english.reviewCardOf(1, 2)), findsOneWidget);
        expect(onCard('a cat'), findsOneWidget);
        expect(onCard('The cat is sleeping.'), findsOneWidget);
        expect(onCard('un chat'), findsNothing);

        await tapOn(tester, find.text(english.reviewShowTranslation));

        expect(onCard('un chat'), findsOneWidget);
      });

      testWidgets('« Je sais » apprend le mot, « À revoir » le garde ; '
          'd\'autres cartes ensuite', (tester) async {
        vocabulary.items.addAll([sampleWord, secondWord]);
        await pump(tester);
        await openReview(tester);

        await tapOn(tester, find.text(english.reviewKnown));

        expect(vocabulary.items.first.learnedAt, isNotNull);
        expect(find.text(english.reviewLearnedCount(1)), findsOneWidget);
        expect(find.text(english.reviewCardOf(2, 2)), findsOneWidget);
        expect(onCard('to sleep'), findsOneWidget);

        await tapOn(tester, find.text(english.reviewAgain));

        expect(vocabulary.items.last.learnedAt, isNull);
        expect(find.text(english.reviewDeckDone), findsOneWidget);

        await tapOn(tester, find.text(english.reviewDeckMore));

        expect(find.text(english.reviewCardOf(1, 1)), findsOneWidget);
        expect(onCard('to sleep'), findsOneWidget);
      });

      testWidgets('si l\'enregistrement échoue, la carte reste et '
          'l\'utilisateur est prévenu', (tester) async {
        vocabulary.items.add(sampleWord);
        await pump(tester);
        await openReview(tester);
        vocabulary.failure = const NetworkFailure();

        await tapOn(tester, find.text(english.reviewKnown));

        expect(find.text(english.errorNetwork), findsOneWidget);
        expect(find.text(english.reviewCardOf(1, 1)), findsOneWidget);
        expect(vocabulary.items.single.learnedAt, isNull);
      });

      testWidgets('tous les mots appris : pas de carte', (tester) async {
        vocabulary.items.add(
          sampleWord.copyWith(learnedAt: DateTime(2026, 11, 18)),
        );
        await pump(tester);
        await openReview(tester);

        expect(find.byType(DailyCard), findsOneWidget);
        expect(find.text(english.reviewKnown), findsNothing);
        expect(find.text(english.reviewDeckDone), findsNothing);
      });
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
      expect(find.text(english.reviewCardOf(1, 1)), findsOneWidget);
      await tester.scrollUntilVisible(wordRow(sampleWord.id), 200);

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

    group('un long historique', () {
      /// 25 journaux, du 25 novembre (journal 1) au 1er novembre (journal 25).
      void seedLongHistory() {
        for (var day = 1; day <= 25; day++) {
          journal.seedPast(
            sampleEntry(
              id: 'entry-$day',
              originalText: 'Journal ${26 - day}.',
              entryDate: DateTime(2026, 11, day),
            ),
          );
        }
      }

      Future<void> scrollToEnd(WidgetTester tester) =>
          tester.scrollUntilVisible(
            find.text('Journal 25.'),
            500,
            scrollable: find.byType(Scrollable).first,
          );

      testWidgets('se charge par pages, à mesure qu\'on le parcourt', (
        tester,
      ) async {
        seedLongHistory();
        await pump(tester);
        await openHistory(tester);

        expect(journal.historyPages, [(offset: 0, limit: 20)]);

        await scrollToEnd(tester);

        expect(journal.historyPages, [
          (offset: 0, limit: 20),
          (offset: 20, limit: 20),
        ]);
        expect(find.text('Journal 25.'), findsOneWidget);
      });

      testWidgets('une page qui ne se charge pas propose de réessayer', (
        tester,
      ) async {
        seedLongHistory();
        journal.nextPageFailure = const NetworkFailure();
        await pump(tester);
        await openHistory(tester);
        await tester.scrollUntilVisible(
          find.text(english.actionRetry),
          500,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text(english.errorNetwork), findsOneWidget);

        journal.nextPageFailure = null;
        await tapOn(tester, find.text(english.actionRetry));
        await scrollToEnd(tester);

        expect(find.text('Journal 25.'), findsOneWidget);
      });
    });
  });
}
