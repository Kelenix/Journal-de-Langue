import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../languages/domain/learning_language.dart';
import '../domain/vocabulary_item.dart';
import '../domain/vocabulary_repository.dart';

class SupabaseVocabularyRepository implements VocabularyRepository {
  const SupabaseVocabularyRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<VocabularyItem>> list(LearningLanguage language) =>
      guardFailures(() async {
        final rows = await _client
            .from('vocabulary_items')
            .select('id, term, translation, example, learned_at')
            .eq('language', language.code)
            .order('created_at', ascending: false)
            .order('term', ascending: true);
        return rows.map(VocabularyItem.fromJson).toList();
      });

  @override
  Future<void> setLearned(String itemId, {required bool isLearned}) =>
      guardFailures(
        () => _client
            .from('vocabulary_items')
            .update({
              'learned_at': isLearned
                  ? DateTime.now().toUtc().toIso8601String()
                  : null,
            })
            .eq('id', itemId),
      );
}
