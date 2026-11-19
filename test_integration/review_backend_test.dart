// Vocabulaire et historique contre le Supabase local, avec un faux serveur Claude.
// Prérequis : voir correction_backend_test.dart.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/utils/uuid.dart';
import 'package:journal_de_langue/features/journal/data/supabase_journal_repository.dart';
import 'package:journal_de_langue/features/journal/domain/journal_entry.dart';
import 'package:journal_de_langue/features/languages/data/supabase_language_repository.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
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

  test(
    'l\'historique contient le journal du jour et rien de verrouillé',
    () async {
      expect(await journal.recentEntries(), isEmpty);

      final entry = await submit();

      expect(await journal.recentEntries(), [entry]);
      expect(
        await journal.historyOverview(),
        const HistoryOverview(historyDays: 4, lockedEntries: 0),
      );
    },
  );
}
