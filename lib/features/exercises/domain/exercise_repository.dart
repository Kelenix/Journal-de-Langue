import '../../languages/domain/learning_language.dart';
import 'exercise.dart';

/// Exercices de l'utilisateur connecté. Toute méthode échoue avec une `Failure`.
abstract interface class ExerciseRepository {
  /// Prochains exercices pour [language]. Peut prendre plusieurs secondes quand
  /// la réserve doit être complétée.
  Future<ExerciseBatch> next({
    required LearningLanguage language,
    required String uiLocale,
    required DateTime day,
  });

  /// Enregistre la réponse et rend la correction.
  Future<ExerciseFeedback> answer({
    required String exerciseId,
    required int choice,
    required DateTime day,
  });
}
