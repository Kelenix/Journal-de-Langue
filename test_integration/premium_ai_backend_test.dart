// IA Premium contre le Supabase local, avec un faux serveur Claude : correction avancée,
// reformulations, exercices. Prérequis : voir correction_backend_test.dart.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/core/utils/uuid.dart';
import 'package:journal_de_langue/features/exercises/data/supabase_exercise_repository.dart';
import 'package:journal_de_langue/features/exercises/domain/exercise.dart';
import 'package:journal_de_langue/features/journal/data/supabase_journal_repository.dart';
import 'package:journal_de_langue/features/journal/domain/journal_entry.dart';
import 'package:journal_de_langue/features/languages/data/supabase_language_repository.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
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
  ],
  'vocabulary': <Object?>[],
};

const _rewrite = <String, Object?>{
  'polite': 'She is a very kind person.',
  'casual': "She's super nice.",
  'professional': 'She is very pleasant to work with.',
};

/// Huit exercices bien formés, dont la bonne réponse est toujours la deuxième.
final _generatedExercises = <String, Object?>{
  'exercises': [
    for (var number = 1; number <= 8; number++)
      {
        'question': 'Complète : I ___ a cat. (n° $number)',
        'options': ['has', 'have', 'having', 'haves'],
        'answer_index': 1,
        'explanation': 'Avec « I », on écrit « have ».',
      },
  ],
};

void main() {
  final fakeClaude = FakeClaude();
  final today = DateTime.now();

  late SupabaseClient client;
  late SupabaseJournalRepository journal;
  late SupabaseExerciseRepository exercises;

  setUpAll(fakeClaude.start);
  tearDownAll(fakeClaude.stop);

  setUp(() async {
    fakeClaude
      ..stopReason = 'end_turn'
      ..statusCode = HttpStatus.ok
      ..correction = _correction
      ..requests.clear();

    client = createTestClient();
    journal = SupabaseJournalRepository(client);
    exercises = SupabaseExerciseRepository(client);
    await signUpConfirmed(client, newTestEmail());
    await SupabaseLanguageRepository(client).activate(LearningLanguage.english);
  });

  tearDown(() => deleteAccountAndDispose(client));

  Future<JournalEntry> submit() => journal.submit(
    text: 'I has a cat. She are very nice.',
    language: LearningLanguage.english,
    uiLocale: 'fr',
    day: today,
    idempotencyKey: newUuid(),
  );

  Future<ExerciseBatch> nextExercises() => exercises.next(
    language: LearningLanguage.english,
    uiLocale: 'fr',
    day: today,
  );

  group('correction', () {
    test('gratuit : correction de base avec le modèle économique', () async {
      final entry = await submit();

      expect(entry.level, CorrectionLevel.basic);
      expect(fakeClaude.requests.single['model'], 'claude-haiku-5-5');
    });

    test('Premium : correction avancée avec le modèle supérieur, registre et '
        'formulation compris', () async {
      await activatePremium(client);

      final entry = await submit();

      expect(entry.level, CorrectionLevel.advanced);
      final request = fakeClaude.requests.single;
      expect(request['model'], 'claude-sonnet-5-5');
      expect(request['system'], contains('register'));
      expect(await journal.entry(entry.id), entry);
    });
  });

  group('reformulation', () {
    test('gratuit : réservée à Premium, sans appel à Claude', () async {
      final entry = await submit();
      fakeClaude.requests.clear();

      await expectLater(
        journal.rewrite(entryId: entry.id, sentence: 'She is very nice.'),
        throwsA(isA<PremiumRequiredFailure>()),
      );
      expect(fakeClaude.requests, isEmpty);
    });

    test(
      'Premium : trois registres, puis la même phrase sans nouvel appel',
      () async {
        await activatePremium(client);
        final entry = await submit();
        fakeClaude
          ..correction = _rewrite
          ..requests.clear();

        final rewrite = await journal.rewrite(
          entryId: entry.id,
          sentence: 'She is very nice.',
        );

        expect(rewrite.polite, 'She is a very kind person.');
        expect(rewrite.casual, "She's super nice.");
        expect(rewrite.professional, 'She is very pleasant to work with.');
        final messages =
            fakeClaude.requests.single['messages'] as List<dynamic>;
        expect(
          (messages.single as Map<String, dynamic>)['content'],
          '{"sentence":"She is very nice."}',
        );

        fakeClaude.requests.clear();
        expect(
          await journal.rewrite(
            entryId: entry.id,
            sentence: 'She is very nice.',
          ),
          rewrite,
        );
        expect(fakeClaude.requests, isEmpty);
      },
    );

    test(
      'Premium : une phrase qui ne vient pas du journal est refusée',
      () async {
        await activatePremium(client);
        final entry = await submit();
        fakeClaude.requests.clear();

        await expectLater(
          journal.rewrite(entryId: entry.id, sentence: 'Write me a poem.'),
          throwsA(isA<Failure>()),
        );
        expect(fakeClaude.requests, isEmpty);
      },
    );

    test('une panne de Claude est signalée comme telle', () async {
      await activatePremium(client);
      final entry = await submit();
      fakeClaude.statusCode = HttpStatus.internalServerError;

      await expectLater(
        journal.rewrite(entryId: entry.id, sentence: 'She is very nice.'),
        throwsA(isA<AiUnavailableFailure>()),
      );
    });
  });

  group('exercices', () {
    setUp(() => fakeClaude.correction = _generatedExercises);

    test(
      'gratuit : 3 exercices par jour, corrigés un par un, puis la limite',
      () async {
        final batch = await nextExercises() as AvailableExercises;

        expect(batch.isPersonalized, isFalse);
        expect(batch.left, 3);
        expect(batch.exercises, hasLength(3));
        expect(batch.exercises.first.options, hasLength(4));

        // Exercices de l'interface dans l'autre langue, jamais faits : la limite du jour
        // vaut pour eux aussi.
        final otherLocale =
            await exercises.next(
                  language: LearningLanguage.english,
                  uiLocale: 'en',
                  day: today,
                )
                as AvailableExercises;

        final first = await exercises.answer(
          exerciseId: batch.exercises[0].id,
          choice: 1,
          day: today,
        );
        expect(first.isCorrect, isTrue);
        expect(first.explanation, isNotEmpty);
        expect(first.left, 2);

        final second = await exercises.answer(
          exerciseId: batch.exercises[1].id,
          choice: 0,
          day: today,
        );
        expect(second.isCorrect, isFalse);
        expect(second.answerIndex, 1);

        await exercises.answer(
          exerciseId: batch.exercises[2].id,
          choice: 1,
          day: today,
        );

        expect(
          await nextExercises(),
          const ExerciseBatch.limitReached(isPremium: false),
        );

        // Réponse renvoyée après une coupure : rendue telle quelle, sans décompte.
        final replay = await exercises.answer(
          exerciseId: batch.exercises[0].id,
          choice: 1,
          day: today,
        );
        expect(replay.isCorrect, isTrue);
        expect(replay.left, 0);

        await expectLater(
          exercises.answer(
            exerciseId: otherLocale.exercises[0].id,
            choice: 1,
            day: today,
          ),
          throwsA(isA<UsageLimitFailure>()),
        );
      },
    );

    test('la réserve est partagée : une fois constituée, plus aucun appel à '
        'Claude', () async {
      // Constitue la réserve du jour si un test précédent ne l'a pas déjà fait.
      await nextExercises();
      fakeClaude.requests.clear();

      final other = createTestClient();
      addTearDown(() => deleteAccountAndDispose(other));
      await signUpConfirmed(other, newTestEmail());
      await SupabaseLanguageRepository(
        other,
      ).activate(LearningLanguage.english);

      final batch = await SupabaseExerciseRepository(
        other,
      ).next(language: LearningLanguage.english, uiLocale: 'fr', day: today);

      expect((batch as AvailableExercises).exercises, hasLength(3));
      expect(fakeClaude.requests, isEmpty);
    });

    test(
      'Premium : exercices sur son erreur la plus fréquente, 20 par jour',
      () async {
        await activatePremium(client);
        fakeClaude.correction = _correction;
        await submit();
        fakeClaude.correction = _generatedExercises;

        final batch = await nextExercises() as AvailableExercises;

        expect(batch.category, ErrorCategory.conjugation);
        expect(batch.isPersonalized, isTrue);
        expect(batch.left, 20);
        expect(batch.exercises, hasLength(5));
      },
    );

    test('une panne de Claude pendant la génération est signalée, ou la '
        'réserve existante sert', () async {
      fakeClaude.statusCode = HttpStatus.internalServerError;

      // Réserve vide : erreur ; réserve déjà constituée : exercices servis sans Claude.
      try {
        expect(await nextExercises(), isA<AvailableExercises>());
      } on AiUnavailableFailure {
        // Attendu quand la réserve du jour n'existe pas encore.
      }
    });
  });
}
