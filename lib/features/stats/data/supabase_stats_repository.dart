import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/utils/dates.dart';
import '../../languages/domain/learning_language.dart';
import '../domain/learning_stats.dart';
import '../domain/stats_repository.dart';

class SupabaseStatsRepository implements StatsRepository {
  const SupabaseStatsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<LearningStats> get({
    required LearningLanguage language,
    required DateTime day,
  }) => guardFailures(() async {
    final stats = await _client.rpc<Map<String, dynamic>>(
      'get_stats',
      params: {'p_language': language.code, 'p_today': isoDate(day)},
    );
    return LearningStats.fromJson(stats);
  });
}
