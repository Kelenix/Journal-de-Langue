import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/features/billing/domain/subscription.dart';
import 'package:journal_de_langue/features/journal/domain/journal_entry.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';

import 'support/fakes.dart';
import 'support/pump_app.dart';

/// Correction avancée, reformulations et exercices, sur des données en mémoire
/// (US-12, US-13, US-14).
void main() {
  late FakeAuthRepository auth;
  late FakeLanguageRepository languages;
  late FakeSubscriptionRepository subscriptions;
  late FakeJournalRepository journal;
  late FakeExerciseRepository exercises;

  setUp(() {
    auth = FakeAuthRepository(userId: FakeAuthRepository.signedInUserId);
    languages = FakeLanguageRepository([LearningLanguage.english]);
    subscriptions = FakeSubscriptionRepository();
    journal = FakeJournalRepository(subscriptions: subscriptions);
    exercises = FakeExerciseRepository(subscriptions: subscriptions);
  });

  void subscribe() => subscriptions.subscription = Subscription(
    plan: SubscriptionPlan.monthly,
    expiresAt: FakeSubscriptionRepository.farFuture,
  );

  Future<void> pump(WidgetTester tester) => pumpApp(
    tester,
    auth: auth,
    languages: languages,
    journal: journal,
    subscriptions: subscriptions,
    exercises: exercises,
  );

  Future<void> tapText(WidgetTester tester, String text) =>
      tapOn(tester, find.text(text));

  /// Ouvre, depuis l'historique, la correction d'un journal déjà corrigé.
  Future<void> openCorrection(
    WidgetTester tester, {
    CorrectionLevel level = CorrectionLevel.basic,
  }) async {
    journal.seedPast(sampleEntry(level: level));
    await pump(tester);
    await tapOn(tester, find.byIcon(Icons.schedule_outlined));
    await tapText(tester, 'I has a cat.');
  }

  /// Phrase de la version corrigée, dans la section « Reformuler ».
  final sentence = find.widgetWithText(ListTile, 'I have a cat.');

  group('correction', () {
    testWidgets('gratuit : correction de base, sans catégorie', (tester) async {
      await openCorrection(tester);

      expect(find.text('With "I", use "have".'), findsOneWidget);
      expect(find.text(english.correctionAdvanced), findsNothing);
      expect(find.text(english.categoryConjugation), findsNothing);
    });

    testWidgets('Premium : correction avancée, chaque faute classée par '
        'catégorie', (tester) async {
      subscribe();

      await openCorrection(tester, level: CorrectionLevel.advanced);

      expect(find.text(english.correctionAdvanced), findsOneWidget);
      expect(find.text(english.categoryConjugation), findsOneWidget);
    });
  });

  group('reformulation', () {
    testWidgets('gratuit : toucher une phrase présente les offres, sans rien '
        'demander au serveur', (tester) async {
      await openCorrection(tester);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      await tapOn(tester, sentence);

      expect(find.text(english.paywallTitle), findsOneWidget);
      expect(find.text(english.paywallBenefitAdvanced), findsOneWidget);
      expect(find.text(english.paywallBenefitExercises), findsOneWidget);
      expect(journal.rewrites, isEmpty);
    });

    testWidgets('Premium : la phrase touchée s\'affiche en version polie, '
        'familière et professionnelle', (tester) async {
      subscribe();
      await openCorrection(tester);
      expect(find.byIcon(Icons.lock_outline), findsNothing);

      await tapOn(tester, sentence);

      const rewrite = FakeJournalRepository.sampleRewrite;
      expect(find.text(english.rewritePolite), findsOneWidget);
      expect(find.text(rewrite.polite), findsOneWidget);
      expect(find.text(english.rewriteCasual), findsOneWidget);
      expect(find.text(rewrite.casual), findsOneWidget);
      expect(find.text(english.rewriteProfessional), findsOneWidget);
      expect(find.text(rewrite.professional), findsOneWidget);
      expect(journal.rewrites, [
        (entryId: 'entry-1', sentence: 'I have a cat.'),
      ]);
    });

    testWidgets('Premium : une reformulation qui échoue propose de réessayer', (
      tester,
    ) async {
      subscribe();
      journal.rewriteFailure = const AiUnavailableFailure();
      await openCorrection(tester);

      await tapOn(tester, sentence);
      expect(find.text(english.errorAiUnavailable), findsOneWidget);

      journal.rewriteFailure = null;
      await tapText(tester, english.actionRetry);

      expect(
        find.text(FakeJournalRepository.sampleRewrite.polite),
        findsOneWidget,
      );
    });
  });

  group('exercices', () {
    Future<void> openExercises(WidgetTester tester) async {
      await pump(tester);
      await tapOn(tester, find.byIcon(Icons.copy_outlined));
      await tapText(tester, english.exercisesTitle);
    }

    Future<void> choose(WidgetTester tester, String option) =>
        tapOn(tester, find.widgetWithText(ListTile, option));

    testWidgets('gratuit : trois questions corrigées une à une, puis le '
        'résultat et la limite du jour', (tester) async {
      await openExercises(tester);

      expect(find.text(english.exerciseProgress(1, 3)), findsOneWidget);
      expect(find.text(english.categoryConjugation), findsOneWidget);
      expect(find.text('I ___ a cat. (1)'), findsOneWidget);

      await choose(tester, 'have');

      expect(find.text(english.exerciseCorrect), findsOneWidget);
      expect(find.text(FakeExerciseRepository.explanation), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNothing);

      // Une question corrigée n'accepte plus de réponse.
      await choose(tester, 'has');
      expect(exercises.answers, hasLength(1));

      await tapText(tester, english.exerciseNext);
      expect(find.text(english.exerciseProgress(2, 3)), findsOneWidget);
      expect(find.text(english.exerciseCorrect), findsNothing);

      await choose(tester, 'has');

      expect(find.text(english.exerciseIncorrect), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);

      await tapText(tester, english.exerciseNext);
      await choose(tester, 'have');
      await tapText(tester, english.exerciseSeeResult);

      expect(find.text(english.exerciseScore(2, 3)), findsOneWidget);
      expect(find.text(english.exercisesLimitFree), findsOneWidget);
      expect(find.text(english.actionContinue), findsNothing);
      // Aucune offre payante avant une première correction.
      expect(find.text(english.paywallDiscover), findsNothing);
      expect(exercises.answers.map((answer) => answer.choice), [1, 0, 1]);

      await tapText(tester, english.exercisesDone);

      expect(find.text(english.exercisesTileBody(3)), findsOneWidget);
    });

    testWidgets('gratuit, limite atteinte après une première correction : '
        'Premium est proposé, et s\'abonner relance une séance', (
      tester,
    ) async {
      journal.seedPast(sampleEntry());
      for (var index = 0; index < 3; index++) {
        await exercises.answer(
          exerciseId: 'exercise-$index',
          choice: FakeExerciseRepository.rightChoice,
          day: testNow,
        );
      }

      await openExercises(tester);

      expect(find.text(english.exercisesLimitFree), findsOneWidget);

      await tapText(tester, english.paywallDiscover);

      expect(find.text(english.paywallTitle), findsOneWidget);

      // S'abonner ramène aux exercices, avec la limite Premium.
      await tapText(tester, english.paywallStartTrial(3));

      expect(find.text(english.paywallTitle), findsNothing);
      expect(find.text(english.exerciseProgress(1, 5)), findsOneWidget);
    });

    testWidgets('Premium : cinq questions sur ses erreurs les plus fréquentes, '
        'puis un nouveau lot', (tester) async {
      subscribe();
      await openExercises(tester);

      expect(find.text(english.exerciseProgress(1, 5)), findsOneWidget);
      expect(
        find.textContaining(english.exercisesPersonalized),
        findsOneWidget,
      );

      for (var question = 1; question <= 5; question++) {
        await choose(tester, 'have');
        await tapText(
          tester,
          question < 5 ? english.exerciseNext : english.exerciseSeeResult,
        );
      }

      expect(find.text(english.exerciseScore(5, 5)), findsOneWidget);
      expect(find.text(english.exercisesLimitPremium), findsNothing);

      await tapText(tester, english.actionContinue);

      expect(find.text(english.exerciseProgress(1, 5)), findsOneWidget);
      expect(find.text('I ___ a cat. (6)'), findsOneWidget);
      expect(exercises.batchesServed, 2);
    });

    testWidgets('des exercices qui ne se chargent pas proposent de réessayer', (
      tester,
    ) async {
      exercises.loadFailure = const AiUnavailableFailure();
      await openExercises(tester);

      expect(find.text(english.errorAiUnavailable), findsOneWidget);

      exercises.loadFailure = null;
      await tapText(tester, english.actionRetry);

      expect(find.text(english.exerciseProgress(1, 3)), findsOneWidget);
    });

    testWidgets('une réponse qui ne part pas est signalée et peut être '
        'redonnée', (tester) async {
      exercises.answerFailure = const NetworkFailure();
      await openExercises(tester);

      await choose(tester, 'have');

      expect(find.text(english.errorNetwork), findsOneWidget);
      expect(find.text(english.exerciseCorrect), findsNothing);

      exercises.answerFailure = null;
      await choose(tester, 'have');

      expect(find.text(english.exerciseCorrect), findsOneWidget);
    });
  });
}
