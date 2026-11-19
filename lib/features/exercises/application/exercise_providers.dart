import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../../core/utils/clock.dart';
import '../../billing/application/billing_providers.dart';
import '../../languages/domain/learning_language.dart';
import '../data/supabase_exercise_repository.dart';
import '../domain/exercise.dart';
import '../domain/exercise_repository.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => SupabaseExerciseRepository(ref.watch(supabaseClientProvider)),
);

/// Réponse donnée à un exercice, avec sa correction.
typedef ExerciseAnswer = ({int choice, ExerciseFeedback feedback});

/// Séance en cours : un lot d'exercices parcouru question après question.
@immutable
class ExerciseSession {
  const ExerciseSession(this.batch, {this.index = 0, this.answers = const []});

  final ExerciseBatch batch;

  /// Position de l'exercice affiché dans le lot ; égale au nombre d'exercices
  /// du lot une fois celui-ci terminé.
  final int index;

  /// Réponses données, dans l'ordre des exercices du lot.
  final List<ExerciseAnswer> answers;

  /// Réponse à l'exercice affiché, s'il a déjà été corrigé.
  ExerciseAnswer? get currentAnswer =>
      index < answers.length ? answers[index] : null;

  int get correctAnswers =>
      answers.where((answer) => answer.feedback.isCorrect).length;
}

/// Ce qui distingue deux séances : la langue travaillée et la langue des
/// explications.
typedef ExerciseSessionKey = ({LearningLanguage language, String uiLocale});

class ExerciseSessionController extends AsyncNotifier<ExerciseSession> {
  ExerciseSessionController(this._key);

  final ExerciseSessionKey _key;

  @override
  Future<ExerciseSession> build() async {
    // Rechargé quand l'offre change : la limite du jour en dépend.
    await ref.watch(subscriptionProvider.future);
    final batch = await ref
        .watch(exerciseRepositoryProvider)
        .next(
          language: _key.language,
          uiLocale: _key.uiLocale,
          day: ref.read(clockProvider)(),
        );
    return ExerciseSession(batch);
  }

  /// Fait corriger [choice] pour [exercise], l'exercice affiché. Échoue avec
  /// une `Failure`, sans rien changer à la séance.
  Future<void> answer(Exercise exercise, int choice) async {
    final feedback = await ref
        .read(exerciseRepositoryProvider)
        .answer(
          exerciseId: exercise.id,
          choice: choice,
          day: ref.read(clockProvider)(),
        );
    if (!ref.mounted) return;

    final session = state.requireValue;
    state = AsyncData(
      ExerciseSession(
        session.batch,
        index: session.index,
        answers: [...session.answers, (choice: choice, feedback: feedback)],
      ),
    );
  }

  /// Passe à l'exercice suivant, ou au résultat après le dernier.
  void next() {
    final session = state.requireValue;
    state = AsyncData(
      ExerciseSession(
        session.batch,
        index: session.index + 1,
        answers: session.answers,
      ),
    );
  }
}

final exerciseSessionProvider = AsyncNotifierProvider.autoDispose
    .family<ExerciseSessionController, ExerciseSession, ExerciseSessionKey>(
      ExerciseSessionController.new,
      // Pas de nouvel essai automatique : l'écran propose « Réessayer ».
      retry: (retryCount, error) => null,
    );
