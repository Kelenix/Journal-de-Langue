import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../domain/content_report_repository.dart';

class SupabaseContentReportRepository implements ContentReportRepository {
  const SupabaseContentReportRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> report(
    ReportedContent content,
    String targetId, {
    String? comment,
  }) => guardFailures(
    () => _client.rpc<void>(
      'report_ai_content',
      params: {
        'p_kind': content.code,
        'p_target_id': targetId,
        'p_comment': comment,
      },
    ),
  );
}
