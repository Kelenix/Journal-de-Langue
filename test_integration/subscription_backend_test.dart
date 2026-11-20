// Abonnement Premium contre le Supabase local : notifications d'achat simulées au
// format RevenueCat, puis effets sur les droits de l'utilisateur.
// Prérequis : voir correction_backend_test.dart.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/core/utils/uuid.dart';
import 'package:journal_de_langue/features/billing/data/supabase_subscription_repository.dart';
import 'package:journal_de_langue/features/billing/domain/subscription.dart';
import 'package:journal_de_langue/features/journal/data/supabase_journal_repository.dart';
import 'package:journal_de_langue/features/journal/domain/journal_entry.dart';
import 'package:journal_de_langue/features/languages/data/supabase_language_repository.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/backend.dart';
import 'support/fake_claude.dart';

void main() {
  final fakeClaude = FakeClaude();
  final today = DateTime.now();

  late SupabaseClient client;
  late SupabaseJournalRepository journal;
  late SupabaseSubscriptionRepository subscriptions;
  late String userId;

  setUpAll(fakeClaude.start);
  tearDownAll(fakeClaude.stop);

  setUp(() async {
    fakeClaude
      ..stopReason = 'end_turn'
      ..statusCode = HttpStatus.ok
      ..correction = const {
        'is_target_language': true,
        'corrected_text': 'Corrected.',
        'items': <Object?>[],
        'vocabulary': <Object?>[],
      };

    client = createTestClient();
    journal = SupabaseJournalRepository(client);
    subscriptions = SupabaseSubscriptionRepository(client);
    await signUpConfirmed(client, newTestEmail());
    await SupabaseLanguageRepository(client).activate(LearningLanguage.english);
    userId = client.auth.currentUser!.id;
  });

  tearDown(() => deleteAccountAndDispose(client));

  /// Notification au format RevenueCat pour l'utilisateur de test.
  Map<String, Object?> event(
    String type, {
    required Duration expiresIn,
    String product = 'premium_annual:annual-base',
    String periodType = 'NORMAL',
    Duration sentAgo = Duration.zero,
    String? id,
    String? cancelReason,
    String? appUserId,
  }) {
    final sentAt = DateTime.now().subtract(sentAgo);
    return {
      'api_version': '1.0',
      'event': {
        'id': id ?? newUuid(),
        'type': type,
        'app_user_id': appUserId ?? userId,
        'original_app_user_id': appUserId ?? userId,
        'aliases': [appUserId ?? userId],
        'product_id': product,
        'period_type': periodType,
        'event_timestamp_ms': sentAt.millisecondsSinceEpoch,
        'expiration_at_ms': DateTime.now()
            .add(expiresIn)
            .millisecondsSinceEpoch,
        'cancel_reason': ?cancelReason,
        'environment': 'SANDBOX',
        'store': 'PLAY_STORE',
      },
    };
  }

  Future<JournalEntry> submit(String text) => journal.submit(
    text: text,
    language: LearningLanguage.english,
    uiLocale: 'fr',
    day: today,
    idempotencyKey: newUuid(),
  );

  test('sans abonnement : offre gratuite', () async {
    expect(await subscriptions.current(), isNull);
    expect((await journal.allowance(today)).plan, isNull);
  });

  test('une notification sans le bon secret est refusée', () async {
    final notification = event(
      'INITIAL_PURCHASE',
      expiresIn: const Duration(days: 3),
    );

    expect((await postWebhook(notification, secret: null)).status, 401);
    expect((await postWebhook(notification, secret: 'mauvais')).status, 401);
    expect(await subscriptions.current(), isNull);
  });

  test('un essai gratuit donne Premium : plus de phrases, plusieurs journaux '
      'par jour', () async {
    final response = await postWebhook(
      event(
        'INITIAL_PURCHASE',
        expiresIn: const Duration(days: 3),
        periodType: 'TRIAL',
      ),
    );
    expect(response.body, {'status': 'applied'});

    final subscription = await subscriptions.current();
    expect(subscription!.plan, SubscriptionPlan.annual);
    expect(subscription.inTrial, isTrue);
    expect(subscription.isActiveAt(DateTime.now()), isTrue);

    final allowance = await journal.allowance(today);
    expect(allowance.plan, SubscriptionPlan.annual);
    expect(allowance.maxSentences, 40);

    await submit('One. Two. Three. Four. Five. Six. Seven. Eight.');
    await submit('A second entry the same day.');
    expect(await journal.historyPage(offset: 0, limit: 20), hasLength(2));
    expect(
      await journal.historyOverview(),
      const HistoryOverview(
        historyDays: null,
        lockedEntries: 0,
        correctedEntries: 2,
      ),
    );
  });

  test(
    'une notification rejouée par RevenueCat n\'est appliquée qu\'une fois',
    () async {
      final notification = event(
        'INITIAL_PURCHASE',
        expiresIn: const Duration(days: 30),
        product: 'premium_monthly',
      );

      expect((await postWebhook(notification)).body, {'status': 'applied'});
      expect((await postWebhook(notification)).body, {'status': 'duplicate'});
      expect((await subscriptions.current())!.plan, SubscriptionPlan.monthly);
    },
  );

  test(
    'à l\'expiration, l\'utilisateur revient à l\'offre gratuite sans perdre '
    'ses journaux',
    () async {
      await postWebhook(
        event(
          'INITIAL_PURCHASE',
          expiresIn: const Duration(days: 7),
          product: 'premium_weekly',
          sentAgo: const Duration(minutes: 2),
        ),
      );
      await submit('Premium entry.');

      await postWebhook(
        event(
          'EXPIRATION',
          expiresIn: Duration.zero,
          product: 'premium_weekly',
        ),
      );

      final subscription = await subscriptions.current();
      expect(subscription!.isActiveAt(DateTime.now()), isFalse);
      final allowance = await journal.allowance(today);
      expect(allowance.plan, isNull);
      expect(allowance.maxSentences, 7);
      expect(allowance.correctionsLeft, 0);
      expect(await journal.historyPage(offset: 0, limit: 20), hasLength(1));
      await expectLater(
        submit('Another one.'),
        throwsA(isA<CorrectionDeniedFailure>()),
      );
    },
  );

  test('un remboursement retire Premium tout de suite', () async {
    await postWebhook(
      event(
        'INITIAL_PURCHASE',
        expiresIn: const Duration(days: 365),
        sentAgo: const Duration(minutes: 2),
      ),
    );
    expect((await journal.allowance(today)).plan, SubscriptionPlan.annual);

    await postWebhook(
      event(
        'CANCELLATION',
        expiresIn: const Duration(days: 365),
        cancelReason: 'CUSTOMER_SUPPORT',
      ),
    );

    expect((await journal.allowance(today)).plan, isNull);
  });

  test('une résiliation simple laisse Premium jusqu\'à l\'échéance', () async {
    await postWebhook(
      event(
        'INITIAL_PURCHASE',
        expiresIn: const Duration(days: 30),
        product: 'premium_monthly',
        sentAgo: const Duration(minutes: 2),
      ),
    );

    await postWebhook(
      event(
        'CANCELLATION',
        expiresIn: const Duration(days: 30),
        product: 'premium_monthly',
        cancelReason: 'UNSUBSCRIBE',
      ),
    );

    expect((await journal.allowance(today)).plan, SubscriptionPlan.monthly);
  });

  test(
    'les notifications sans effet reçoivent quand même une réponse 200',
    () async {
      final unknownUser = await postWebhook(
        event(
          'INITIAL_PURCHASE',
          expiresIn: const Duration(days: 30),
          appUserId: r'$RCAnonymousID:0123456789abcdef',
        ),
      );
      final otherProduct = await postWebhook(
        event(
          'NON_RENEWING_PURCHASE',
          expiresIn: const Duration(days: 30),
          product: 'pack_10_corrections',
        ),
      );

      expect(unknownUser.status, 200);
      expect(unknownUser.body, {'status': 'ignored'});
      expect(otherProduct.body, {'status': 'ignored'});
      expect(await subscriptions.current(), isNull);
    },
  );

  test('une notification mal formée est refusée', () async {
    expect((await postWebhook(const {'event': 'pas un objet'})).status, 400);
  });
}
