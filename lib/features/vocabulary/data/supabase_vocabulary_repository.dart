import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../languages/domain/learning_language.dart';
import '../domain/vocabulary_item.dart';
import '../domain/vocabulary_repository.dart';

class SupabaseVocabularyRepository implements VocabularyRepository {
  const SupabaseVocabularyRepository(this._client);

  /// Lignes par requête, sous la limite de l'API (`max_rows`) qui tronquerait
  /// sans erreur un vocabulaire plus grand.
  static const _batchSize = 500;

  final SupabaseClient _client;

  @override
  Future<List<VocabularyItem>> list(LearningLanguage language) =>
      guardFailures(() async {
        final items = <VocabularyItem>[];
        while (true) {
          final rows = await _client
              .from('vocabulary_items')
              .select('id, term, translation, example, learned_at')
              .eq('language', language.code)
              .order('created_at', ascending: false)
              .order('term', ascending: true)
              .order('id', ascending: true)
              .range(items.length, items.length + _batchSize - 1);
          items.addAll(rows.map(VocabularyItem.fromJson));
          if (rows.length < _batchSize) return items;
        }
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
