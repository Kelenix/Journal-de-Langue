// Chaîne de correction complète contre le Supabase local : app → fonction
// `correct-entry` → base, avec un faux serveur Claude.
// Prérequis : `supabase start`, `env/dev.json`, puis dans un autre terminal
//   supabase functions serve --env-file supabase/functions/.env.test
// Lancer : flutter test test_integration
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/core/utils/uuid.dart';
import 'package:journal_de_langue/features/journal/data/supabase_journal_repository.dart';
import 'package:journal_de_langue/features/journal/domain/journal_entry.dart';
import 'package:journal_de_langue/features/languages/data/supabase_language_repository.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/backend.dart';
import 'support/fake_claude.dart';

const _text = 'I has a cat. She are very nice.';
const _goodCorrection = <String, Object?>{
  'is_target_language': true,
  'corrected_text': 'I have a cat. She is very nice.',
  'items': [
    {
      'original': 'has',
      'corrected': 'have',
      'category': 'conjugation',
      'explanation': 'Avec « I », le verbe « to have » se conjugue « have ».',
    },
    {
      'original': 'are',
      'corrected': 'is',
      'category': 'conjugation',
      'explanation': 'Avec « she », le verbe « to be » se conjugue « is ».',
    },
  ],
};

void main() {
  final fakeClaude = FakeClaude();
  final today = DateTime.now();

  late SupabaseClient client;
  late SupabaseJournalRepository journal;

  setUpAll(fakeClaude.start);
  tearDownAll(fakeClaude.stop);

  setUp(() async {
    fakeClaude
      ..correction = _goodCorrection
      ..stopReason = 'end_turn'
      ..statusCode = HttpStatus.ok
      ..requests.clear();

    client = createTestClient();
    journal = SupabaseJournalRepository(client);
    await signUpConfirmed(client, newTestEmail());
    await SupabaseLanguageRepository(client).activate(LearningLanguage.english);
  });

  tearDown(() => deleteAccountAndDispose(client));

  Future<JournalEntry> submit({String text = _text, String? key}) =>
      journal.submit(
        text: text,
        language: LearningLanguage.english,
        uiLocale: 'fr',
        day: today,
        idempotencyKey: key ?? newUuid(),
      );

  Matcher deniedFor(CorrectionDenial reason) => throwsA(
    isA<CorrectionDeniedFailure>().having((f) => f.reason, 'reason', reason),
  );

  test(
    'avant tout journal : 7 phrases, 1000 caractères, 1 correction',
    () async {
      expect(
        await journal.allowance(today),
        const JournalAllowance(
          maxSentences: 7,
          maxCharacters: 1000,
          correctionsLeft: 1,
        ),
      );
      expect(await journal.entryOfDay(today), isNull);
    },
  );

  test('un journal soumis revient corrigé, expliqué, et se relit', () async {
    final entry = await submit();

    expect(entry.originalText, _text);
    expect(entry.correctedText, 'I have a cat. She is very nice.');
    expect(entry.language, LearningLanguage.english);
    expect(entry.items.map((item) => item.original), ['has', 'are']);
    expect(entry.items.first.category, ErrorCategory.conjugation);
    expect(entry.items.first.explanation, contains('have'));

    expect(await journal.entry(entry.id), entry);
    expect(await journal.entryOfDay(today), entry);
    expect((await journal.allowance(today)).correctionsLeft, 0);
  });

  test(
    'le texte part vers Claude comme donnée, avec le modèle économique',
    () async {
      await submit();

      final request = fakeClaude.requests.single;
      expect(request['model'], 'claude-haiku-5-5');
      expect(request['system'], contains('English'));
      expect(request['system'], contains('French'));
      final messages = request['messages'] as List<dynamic>;
      expect(
        (messages.single as Map<String, dynamic>)['content'],
        '{"journal_entry":"$_text"}',
      );
    },
  );

  test(
    'un second journal le même jour est refusé sans appeler Claude',
    () async {
      await submit();
      fakeClaude.requests.clear();

      await expectLater(
        submit(text: 'Another day.'),
        deniedFor(CorrectionDenial.dailyLimit),
      );
      expect(fakeClaude.requests, isEmpty);
    },
  );

  test('le même envoi rejoué rend la correction sans nouvel appel', () async {
    final key = newUuid();
    final first = await submit(key: key);
    fakeClaude.requests.clear();

    final replayed = await submit(key: key);

    expect(replayed, first);
    expect(fakeClaude.requests, isEmpty);
  });

  test('plus de 7 phrases : refusé sans appeler Claude', () async {
    await expectLater(
      submit(text: 'A. B. C. D. E. F. G. H.'),
      deniedFor(CorrectionDenial.tooManySentences),
    );
    expect(fakeClaude.requests, isEmpty);
  });

  test('une langue non active est refusée', () async {
    await expectLater(
      journal.submit(
        text: 'Hola.',
        language: LearningLanguage.spanish,
        uiLocale: 'fr',
        day: today,
        idempotencyKey: newUuid(),
      ),
      deniedFor(CorrectionDenial.languageNotActive),
    );
  });

  test('une panne de Claude ne consomme pas la correction du jour', () async {
    fakeClaude.statusCode = HttpStatus.internalServerError;

    await expectLater(submit(), throwsA(isA<AiUnavailableFailure>()));
    expect((await journal.allowance(today)).correctionsLeft, 1);

    fakeClaude.statusCode = HttpStatus.ok;
    expect((await submit()).correctedText, isNotEmpty);
  });

  test(
    'une réponse tronquée de Claude ne consomme pas la correction',
    () async {
      fakeClaude.stopReason = 'max_tokens';

      await expectLater(submit(), throwsA(isA<AiUnavailableFailure>()));
      expect((await journal.allowance(today)).correctionsLeft, 1);
    },
  );

  test(
    'un texte écrit dans une autre langue est signalé, sans débit',
    () async {
      fakeClaude.correction = const {
        'is_target_language': false,
        'corrected_text': '',
        'items': <Object?>[],
      };

      await expectLater(
        submit(text: 'Bonjour, je suis content.'),
        deniedFor(CorrectionDenial.wrongLanguage),
      );
      expect((await journal.allowance(today)).correctionsLeft, 1);
    },
  );

  test('sans session, la fonction refuse la demande', () async {
    await client.auth.signOut(scope: SignOutScope.local);

    await expectLater(submit(), throwsA(isA<Failure>()));
    expect(fakeClaude.requests, isEmpty);
  });
}
