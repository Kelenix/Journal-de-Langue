import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../data/supabase_content_report_repository.dart';
import '../domain/content_report_repository.dart';

final contentReportRepositoryProvider = Provider<ContentReportRepository>(
  (ref) => SupabaseContentReportRepository(ref.watch(supabaseClientProvider)),
);
