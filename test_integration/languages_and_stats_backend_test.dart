// Langues selon l'offre et statistiques contre le Supabase local, avec un faux
// serveur Claude. Prérequis : voir correction_backend_test.dart.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/core/utils/uuid.dart';
import 'package:journal_de_langue/features/journal/data/supabase_journal_repository.dart';
import 'package:journal_de_langue/features/journal/domain/journal_entry.dart';
import 'package:journal_de_langue/features/languages/data/supabase_language_repository.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:journal_de_langue/features/stats/data/supabase_stats_repository.dart';
import 'package:journal_de_langue/features/stats/domain/learning_stats.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/backend.dart';
import 'support/fake_claude.dart';

const _correction = <String, Object?>{
  'is_target_language': true,
  'corrected_text': 'I have a cat. She is very nice.',
  'items': [
    {
      'original': 'has',
      'corrected': 'have',
      'category': 'conjugation',
      'explanation': 'Avec « I », on écrit « have ».',
    },
    {
      'original': 'are',
      'corrected': 'is',
      'category': 'conjugation',
      'explanation': 'Avec « she », on écrit « is ».',
    },
  ],
  'vocabulary': <Object?>[],
};

void main() {
  final fakeClaude = FakeClaude();
  final today = DateTime.now();

  late SupabaseClient client;
  late SupabaseLanguageRepository languages;
  late SupabaseStatsRepository stats;

  setUpAll(fakeClaude.start);
  tearDownAll(fakeClaude.stop);

  setUp(() async {
    fakeClaude
      ..stopReason = 'end_turn'
      ..statusCode = HttpStatus.ok
      ..correction = _correction
      ..requests.clear();

    client = createTestClient();
    languages = SupabaseLanguageRepository(client);
    stats = SupabaseStatsRepository(client);
    await signUpConfirmed(client, newTestEmail());
    await languages.activate(LearningLanguage.english);
  });

  tearDown(() => deleteAccountAndDispose(client));

  Future<JournalEntry> submit() => SupabaseJournalRepository(client).submit(
    text: 'I has a cat. She are very nice.',
    language: LearningLanguage.english,
    uiLocale: 'fr',
    day: today,
    idempotencyKey: newUuid(),
  );

  group('langues', () {
    test('gratuit : la nouvelle langue remplace l\'ancienne', () async {
      await languages.activate(LearningLanguage.spanish);

      expect(await languages.activeLanguages(), [LearningLanguage.spanish]);
    });

    test('Premium mensuel : trois langues, la dernière choisie d\'abord, pas '
        'de quatrième', () async {
      await activatePremium(client);
      await languages.activate(LearningLanguage.spanish);
      await languages.activate(LearningLanguage.german);

      expect(await languages.activeLanguages(), [
        LearningLanguage.german,
        LearningLanguage.spanish,
        LearningLanguage.english,
      ]);
      await expectLater(
        languages.activate(LearningLanguage.french),
        throwsA(isA<LanguageLimitFailure>()),
      );

      await languages.deactivate(LearningLanguage.spanish);
      await languages.activate(LearningLanguage.english);

      expect(await languages.activeLanguages(), [
        LearningLanguage.english,
        LearningLanguage.german,
      ]);
    });
  });

  group('statistiques', () {
    test('gratuit : la série et le nombre de journaux, sans plus', () async {
      expect(
        await stats.get(language: LearningLanguage.english, day: today),
        const LearningStats(isPremium: false, streakDays: 0, journals: 0),
      );

      await submit();

      expect(
        await stats.get(language: LearningLanguage.english, day: today),
        LearningStats(
          isPremium: false,
          streakDays: 1,
          journals: 1,
          // Le journal du jour compte dans la semaine en cours.
          weekDays: [DateTime(today.year, today.month, today.day)],
        ),
      );
    });

    test('Premium : fautes par type et par phrase', () async {
      await activatePremium(client);
      await submit();

      final premium = await stats.get(
        language: LearningLanguage.english,
        day: today,
      );

      expect(premium.isPremium, isTrue);
      expect(premium.streakDays, 1);
      expect(premium.wordsLearned, 0);
      expect(premium.mistakesByCategory, [
        const CategoryCount(category: ErrorCategory.conjugation, count: 2),
      ]);
      expect(premium.weeklyMistakeRate.single.mistakesPerSentence, 1.0);
    });
  });
}
