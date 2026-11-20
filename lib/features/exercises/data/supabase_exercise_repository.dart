import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/dates.dart';
import '../../journal/domain/journal_entry.dart';
import '../../languages/domain/learning_language.dart';
import '../domain/exercise.dart';
import '../domain/exercise_repository.dart';

class SupabaseExerciseRepository implements ExerciseRepository {
  const SupabaseExerciseRepository(this._client);

  static const _statusLimit = 'limit';
  static const _statusOk = 'ok';

  final SupabaseClient _client;

  @override
  Future<ExerciseBatch> next({
    required LearningLanguage language,
    required String uiLocale,
    required DateTime day,
  }) => guardFailures(() async {
    // Génération d'exercices par Claude comprise (deux essais de 25 s au plus).
    final response = await _client.functions
        .invoke(
          'next-exercises',
          body: {
            'language': language.code,
            'ui_locale': uiLocale,
            'local_date': isoDate(day),
          },
        )
        .timeout(const Duration(seconds: 60));
    final batch = response.data as Map<String, dynamic>;
    if (batch['status'] == _statusLimit) {
      return ExerciseBatch.limitReached(isPremium: batch['is_premium'] as bool);
    }
    return ExerciseBatch.available(
      category: ErrorCategory.values.byName(batch['category'] as String),
      isPersonalized: batch['is_personalized'] as bool,
      left: batch['left'] as int,
      exercises: [
        for (final exercise in batch['exercises'] as List<dynamic>)
          Exercise.fromJson(exercise as Map<String, dynamic>),
      ],
    );
  });

  @override
  Future<ExerciseFeedback> answer({
    required String exerciseId,
    required int choice,
    required DateTime day,
  }) => guardFailures(() async {
    final result = await _client.rpc<Map<String, dynamic>>(
      'answer_exercise',
      params: {
        'p_exercise_id': exerciseId,
        'p_choice': choice,
        'p_attempt_date': isoDate(day),
      },
    );
    return switch (result['status']) {
      _statusOk => ExerciseFeedback.fromJson(result),
      _statusLimit => throw const UsageLimitFailure(),
      _ => throw const UnexpectedFailure(),
    };
  });
}
