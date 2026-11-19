import 'package:freezed_annotation/freezed_annotation.dart';

import '../../journal/domain/journal_entry.dart';

part 'exercise.freezed.dart';
part 'exercise.g.dart';

/// Question à choix multiple. La bonne réponse reste sur le serveur jusqu'à ce
/// que l'utilisateur ait répondu.
@freezed
abstract class Exercise with _$Exercise {
  const factory Exercise({
    required String id,
    required String question,
    required List<String> options,
  }) = _Exercise;

  factory Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);
}

/// Ce que le serveur propose à l'utilisateur pour s'entraîner maintenant.
@freezed
sealed class ExerciseBatch with _$ExerciseBatch {
  const factory ExerciseBatch.available({
    /// Type d'erreur travaillé.
    required ErrorCategory category,

    /// Vrai si le type vient des erreurs de l'utilisateur (Premium).
    required bool isPersonalized,

    /// Exercices encore permis aujourd'hui par l'offre, ceux-ci compris.
    required int left,
    required List<Exercise> exercises,
  }) = AvailableExercises;

  /// La limite quotidienne de l'offre est atteinte.
  const factory ExerciseBatch.limitReached({required bool isPremium}) =
      ExerciseLimitReached;
}

/// Correction d'une réponse.
@freezed
abstract class ExerciseFeedback with _$ExerciseFeedback {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ExerciseFeedback({
    required bool isCorrect,
    required int answerIndex,
    required String explanation,

    /// Exercices encore permis aujourd'hui après cette réponse.
    required int left,
  }) = _ExerciseFeedback;

  factory ExerciseFeedback.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFeedbackFromJson(json);
}
