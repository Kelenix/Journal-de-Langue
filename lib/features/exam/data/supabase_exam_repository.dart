import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../languages/domain/learning_language.dart';
import '../domain/exam.dart';
import '../domain/exam_repository.dart';

class SupabaseExamRepository implements ExamRepository {
  const SupabaseExamRepository(this._client);

  static const _columns =
      'id, language, level, status, prompt, answer, result, created_at, graded_at';

  final SupabaseClient _client;

  @override
  Future<List<Exam>> list() => guardFailures(() async {
    // La RLS ne laisse voir que les simulations de l'utilisateur connecté.
    final rows = await _client
        .from('exams')
        .select(_columns)
        .neq('status', 'preparing')
        .order('created_at', ascending: false);
    return rows.map(Exam.fromJson).toList();
  });

  @override
  Future<Exam> start({
    required LearningLanguage language,
    required ExamLevel level,
    required String uiLocale,
  }) => _invoke({
    'action': 'start',
    'language': language.code,
    'level': level.code,
    'ui_locale': uiLocale,
  });

  @override
  Future<void> saveDraft({required String examId, required String answer}) =>
      guardFailures(
        () => _client.rpc<void>(
          'save_exam_draft',
          params: {'p_exam_id': examId, 'p_answer': answer},
        ),
      );

  @override
  Future<Exam> submit({required String examId, required String answer}) =>
      _invoke({'action': 'submit', 'exam_id': examId, 'answer': answer});

  Future<Exam> _invoke(Map<String, Object> body) => guardFailures(() async {
    final response = await _client.functions.invoke('exam', body: body);
    return Exam.fromJson(response.data as Map<String, dynamic>);
  });
}
