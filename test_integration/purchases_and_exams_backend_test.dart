// Achats à l'unité et simulation d'examen contre le Supabase local, avec un faux serveur
// Claude. Prérequis : voir correction_backend_test.dart.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/core/utils/uuid.dart';
import 'package:journal_de_langue/features/billing/data/supabase_wallet_repository.dart';
import 'package:journal_de_langue/features/exam/data/supabase_exam_repository.dart';
import 'package:journal_de_langue/features/exam/domain/exam.dart';
import 'package:journal_de_langue/features/journal/data/supabase_journal_repository.dart';
import 'package:journal_de_langue/features/languages/data/supabase_language_repository.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/backend.dart';
import 'support/fake_claude.dart';

const _correction = <String, Object?>{
  'is_target_language': true,
  'corrected_text': 'I have a cat.',
  'items': <Object?>[],
  'vocabulary': <Object?>[],
};

const _topic = <String, Object?>{
  'title': 'A letter to a friend',
  'task': 'Write to a friend about your last holiday.',
  'min_words': 120,
  'max_words': 180,
};

const _grading = <String, Object?>{
  // Hors bornes : la fonction ramène la note sur 20 et les critères sur 5.
  'score': 25,
  'level_estimate': 'B1',
  'summary': 'Clear and well organised.',
  'criteria': [
    {'criterion': 'grammar', 'score': 7, 'comment': 'Check past tenses.'},
    {'criterion': 'task', 'score': 4, 'comment': 'Complete.'},
  ],
  'corrected_text': 'Last summer I went to Rome.',
  'items': [
    {
      'original': 'goed',
      'corrected': 'went',
      'category': 'conjugation',
      'explanation': 'Le verbe « go » est irrégulier.',
    },
  ],
  'revision_plan': [
    {
      'title': 'Verbes irréguliers',
      'details': 'Apprends les 50 plus courants.',
    },
  ],
};

void main() {
  final fakeClaude = FakeClaude();
  final today = DateTime.now();

  late SupabaseClient client;
  late SupabaseWalletRepository wallets;
  late SupabaseJournalRepository journal;
  late SupabaseExamRepository exams;

  setUpAll(fakeClaude.start);
  tearDownAll(fakeClaude.stop);

  setUp(() async {
    fakeClaude
      ..stopReason = 'end_turn'
      ..statusCode = HttpStatus.ok
      ..correction = _correction
      ..requests.clear();

    client = createTestClient();
    wallets = SupabaseWalletRepository(client);
    journal = SupabaseJournalRepository(client);
    exams = SupabaseExamRepository(client);
    await signUpConfirmed(client, newTestEmail());
    await SupabaseLanguageRepository(client).activate(LearningLanguage.english);
  });

  tearDown(() => deleteAccountAndDispose(client));

  /// Notification d'achat unique (ou de son remboursement), comme RevenueCat.
  Future<void> storeEvent(
    String productId,
    String transactionId, {
    String type = 'NON_RENEWING_PURCHASE',
    String? cancelReason,
  }) async {
    final now = DateTime.now();
    final response = await postWebhook({
      'api_version': '1.0',
      'event': {
        'id': 'test-${now.microsecondsSinceEpoch}',
        'type': type,
        'app_user_id': client.auth.currentUser!.id,
        'product_id': productId,
        'transaction_id': transactionId,
        'quantity': 1,
        'cancel_reason': ?cancelReason,
        'event_timestamp_ms': now.millisecondsSinceEpoch,
      },
    });
    expect(response.body, {'status': 'applied'});
  }

  Future<void> submitJournal() => journal.submit(
    text: 'I has a cat.',
    language: LearningLanguage.english,
    uiLocale: 'fr',
    day: today,
    idempotencyKey: newUuid(),
  );

  test('10 corrections achetées : la correction gratuite d\'abord, puis un '
      'crédit par correction', () async {
    final transaction = 'tx-${newUuid()}';
    await storeEvent('corrections_10', transaction);
    expect((await wallets.current()).correctionCredits, 10);

    await submitJournal();
    expect((await wallets.current()).correctionCredits, 10);

    await submitJournal();
    final allowance = await journal.allowance(today);
    expect(allowance.correctionsLeft, 0);
    expect(allowance.credits, 9);

    // Remboursé : le pack est repris, sans descendre sous zéro.
    await storeEvent(
      'corrections_10',
      transaction,
      type: 'CANCELLATION',
      cancelReason: 'CUSTOMER_SUPPORT',
    );
    expect((await wallets.current()).correctionCredits, 0);
    await expectLater(
      submitJournal(),
      throwsA(
        isA<CorrectionDeniedFailure>().having(
          (failure) => failure.reason,
          'reason',
          CorrectionDenial.dailyLimit,
        ),
      ),
    );
  });

  test('un accès de 30 jours ajoute une langue ; sans publicité est '
      'enregistré', () async {
    await storeEvent('language_pass_es', 'tx-${newUuid()}');
    await storeEvent('remove_ads', 'tx-${newUuid()}');

    final wallet = await wallets.current();
    expect(wallet.adsRemoved, isTrue);
    expect(wallet.languagePasses.single.language, LearningLanguage.spanish);
    expect(
      wallet.languagePasses.single.expiresAt.difference(DateTime.now()).inDays,
      29,
    );
    expect(await SupabaseLanguageRepository(client).activeLanguages(), [
      LearningLanguage.spanish,
      LearningLanguage.english,
    ]);
  });

  test('simulation d\'examen : sujet, brouillon, copie notée et plan de '
      'révision', () async {
    await expectLater(
      exams.start(
        language: LearningLanguage.english,
        level: ExamLevel.b2,
        uiLocale: 'fr',
      ),
      throwsA(isA<NoExamCreditFailure>()),
    );

    await storeEvent('exam_pack', 'tx-${newUuid()}');
    fakeClaude.correction = _topic;
    final exam = await exams.start(
      language: LearningLanguage.english,
      level: ExamLevel.b2,
      uiLocale: 'fr',
    );

    expect(exam.status, ExamStatus.inProgress);
    expect(exam.level, ExamLevel.b2);
    expect(exam.prompt?.task, 'Write to a friend about your last holiday.');
    expect((await wallets.current()).examCredits, 0);
    expect(fakeClaude.requests.single['model'], 'claude-sonnet-5-5');

    // Interrompue puis reprise : même simulation, sans nouveau sujet ni débit.
    await exams.saveDraft(examId: exam.id, answer: 'Last summer I');
    fakeClaude.requests.clear();
    final resumed = await exams.start(
      language: LearningLanguage.english,
      level: ExamLevel.a2,
      uiLocale: 'fr',
    );
    expect(resumed.id, exam.id);
    expect(resumed.answer, 'Last summer I');
    expect(fakeClaude.requests, isEmpty);

    fakeClaude.correction = _grading;
    final graded = await exams.submit(
      examId: exam.id,
      answer: 'Last summer I goed to Rome.',
    );

    final result = graded.result!;
    expect(graded.status, ExamStatus.graded);
    expect(result.score, 20);
    expect(result.criteria.map((criterion) => criterion.criterion), [
      ExamCriterion.task,
      ExamCriterion.grammar,
    ]);
    expect(result.criteria.last.score, 5);
    expect(result.items.single.corrected, 'went');
    expect(result.revisionPlan.single.title, 'Verbes irréguliers');
    expect((await exams.list()).single.id, exam.id);
  });

  test('un sujet impossible à créer rend le pack', () async {
    await storeEvent('exam_pack', 'tx-${newUuid()}');
    fakeClaude.statusCode = HttpStatus.internalServerError;

    await expectLater(
      exams.start(
        language: LearningLanguage.english,
        level: ExamLevel.b1,
        uiLocale: 'fr',
      ),
      throwsA(isA<AiUnavailableFailure>()),
    );
    expect((await wallets.current()).examCredits, 1);
    expect(await exams.list(), isEmpty);
  });
}
