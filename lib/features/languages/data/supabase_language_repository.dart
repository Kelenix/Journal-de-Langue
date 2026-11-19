import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/language_repository.dart';
import '../domain/learning_language.dart';

class SupabaseLanguageRepository implements LanguageRepository {
  const SupabaseLanguageRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<LearningLanguage>> activeLanguages() => guardFailures(() async {
    final rows = await _client
        .from('user_languages')
        .select('language')
        .eq('is_active', true)
        .order('activated_at', ascending: true);
    return [
      for (final row in rows)
        LearningLanguage.fromCode(row['language'] as String),
    ];
  });

  @override
  Future<void> activate(LearningLanguage language) => guardFailures(
    () => _client.rpc<void>(
      'activate_language',
      params: {'p_language': language.code},
    ),
  );
}
