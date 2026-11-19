import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/language_repository.dart';
import '../domain/learning_language.dart';

class SupabaseLanguageRepository implements LanguageRepository {
  const SupabaseLanguageRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<LearningLanguage>> activeLanguages() => guardFailures(() async {
    // La limite de l'offre est appliquée par le serveur.
    final codes = await _client.rpc<List<dynamic>>('get_languages');
    return [
      for (final code in codes) LearningLanguage.fromCode(code as String),
    ];
  });

  @override
  Future<void> activate(LearningLanguage language) => guardFailures(
    () => _client.rpc<void>(
      'activate_language',
      params: {'p_language': language.code},
    ),
  );

  @override
  Future<void> deactivate(LearningLanguage language) => guardFailures(
    () => _client.rpc<void>(
      'deactivate_language',
      params: {'p_language': language.code},
    ),
  );
}
