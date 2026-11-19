import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../../core/utils/clock.dart';
import '../../billing/application/billing_providers.dart';
import '../../languages/application/language_providers.dart';
import '../data/supabase_stats_repository.dart';
import '../domain/learning_stats.dart';
import '../domain/stats_repository.dart';

final statsRepositoryProvider = Provider<StatsRepository>(
  (ref) => SupabaseStatsRepository(ref.watch(supabaseClientProvider)),
);

/// Progrès dans la langue en cours ; `null` sans langue. Recalculé quand la
/// langue ou l'offre change, et après chaque correction.
final statsProvider = FutureProvider.autoDispose<LearningStats?>((ref) async {
  await ref.watch(subscriptionProvider.future);
  final languages = await ref.watch(activeLanguagesProvider.future);
  final language = languages.firstOrNull;
  if (language == null) return null;
  return ref
      .watch(statsRepositoryProvider)
      .get(language: language, day: ref.watch(clockProvider)());
}, retry: (retryCount, error) => null);
