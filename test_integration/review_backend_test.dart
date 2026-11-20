// Vocabulaire et historique contre le Supabase local, avec un faux serveur Claude.
// Prérequis : voir correction_backend_test.dart.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/core/utils/uuid.dart';
import 'package:journal_de_langue/features/journal/data/supabase_journal_repository.dart';
import 'package:journal_de_langue/features/journal/domain/journal_entry.dart';
import 'package:journal_de_langue/features/languages/data/supabase_language_repository.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:journal_de_langue/features/reports/data/supabase_content_report_repository.dart';
import 'package:journal_de_langue/features/reports/domain/content_report_repository.dart';
import 'package:journal_de_langue/features/vocabulary/data/supabase_vocabulary_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/backend.dart';
import 'support/fake_claude.dart';

Map<String, String> _word(String term) => {
  'term': term,
  'translation': 'traduction de $term',
  'example': 'An example with $term.',
};

void main() {
  final fakeClaude = FakeClaude();
  final today = DateTime.now();

  late SupabaseClient client;
  late SupabaseJournalRepository journal;
  late SupabaseVocabularyRepository vocabulary;

  setUpAll(fakeClaude.start);
  tearDownAll(fakeClaude.stop);

  setUp(() async {
    fakeClaude
      ..stopReason = 'end_turn'
      ..statusCode = HttpStatus.ok
      ..correction = {
        'is_target_language': true,
        'corrected_text': 'I have a cat.',
        'items': [
          {
            'original': 'has',
            'corrected': 'have',
            'category': 'conjugation',
            'explanation': 'Avec « I », on écrit « have ».',
          },
        ],
        // Sept mots, dont un doublon et un terme vide : cinq au plus sont gardés.
        'vocabulary': [
          _word('a cat'),
          _word('A Cat'),
          _word(' '),
          _word('to have'),
          _word('a sofa'),
          _word('to sleep'),
          _word('nice'),
        ],
      };

    client = createTestClient();
    journal = SupabaseJournalRepository(client);
    vocabulary = SupabaseVocabularyRepository(client);
    await signUpConfirmed(client, newTestEmail());
    await SupabaseLanguageRepository(client).activate(LearningLanguage.english);
  });

  tearDown(() => deleteAccountAndDispose(client));

  Future<JournalEntry> submit() => journal.submit(
    text: 'I has a cat.',
    language: LearningLanguage.english,
    uiLocale: 'fr',
    day: today,
    idempotencyKey: newUuid(),
  );

  test(
    'une correction apporte au plus 5 mots, sans doublon ni terme vide',
    () async {
      final entry = await submit();

      expect(entry.vocabulary.map((word) => word.term), [
        'a cat',
        'a sofa',
        'to have',
        'to sleep',
      ]);
      expect(entry.vocabulary.first.translation, 'traduction de a cat');
      expect(entry.vocabulary.first.learnedAt, isNull);
      expect(await vocabulary.list(LearningLanguage.english), entry.vocabulary);
      expect(await journal.entry(entry.id), entry);
    },
  );

  test(
    'un mot marqué comme appris le reste, puis peut être remis à réviser',
    () async {
      final word = (await submit()).vocabulary.first;

      await vocabulary.setLearned(word.id, isLearned: true);
      final learned = await vocabulary.list(LearningLanguage.english);
      expect(
        learned.firstWhere((item) => item.id == word.id).learnedAt,
        isNotNull,
      );

      await vocabulary.setLearned(word.id, isLearned: false);
      final reviewed = await vocabulary.list(LearningLanguage.english);
      expect(
        reviewed.firstWhere((item) => item.id == word.id).learnedAt,
        isNull,
      );
    },
  );

  test('le vocabulaire est rangé par langue', () async {
    await submit();

    expect(await vocabulary.list(LearningLanguage.spanish), isEmpty);
  });

  test('une correction se signale, mais pas comme un autre contenu', () async {
    final entry = await submit();
    final reports = SupabaseContentReportRepository(client);

    await reports.report(
      ReportedContent.correction,
      entry.id,
      comment: 'Faux.',
    );
    await expectLater(
      reports.report(ReportedContent.exam, entry.id),
      throwsA(isA<Failure>()),
    );
  });

  test('l\'historique se lit par pages, sans le vocabulaire, et l\'export '
      'reprend les journaux de la langue', () async {
    expect(await journal.historyPage(offset: 0, limit: 20), isEmpty);

    final entry = await submit();

    final page = await journal.historyPage(offset: 0, limit: 20);
    expect(page.single.id, entry.id);
    expect(page.single.items, entry.items);
    expect(page.single.vocabulary, isEmpty);
    expect(await journal.historyPage(offset: 1, limit: 20), isEmpty);
    expect(await journal.entriesSince(LearningLanguage.english), [entry]);
    expect(
      await journal.entriesSince(
        LearningLanguage.english,
        firstDay: today.add(const Duration(days: 1)),
      ),
      isEmpty,
    );
    expect(
      await journal.historyOverview(),
      const HistoryOverview(
        historyDays: 4,
        lockedEntries: 0,
        correctedEntries: 1,
      ),
    );
  });
}
