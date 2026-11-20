import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../../core/utils/clock.dart';
import '../../languages/application/language_providers.dart';
import '../data/supabase_vocabulary_repository.dart';
import '../domain/vocabulary_item.dart';
import '../domain/vocabulary_repository.dart';

final vocabularyRepositoryProvider = Provider<VocabularyRepository>(
  (ref) => SupabaseVocabularyRepository(ref.watch(supabaseClientProvider)),
);

/// Vocabulaire de la langue active.
class VocabularyNotifier extends AsyncNotifier<List<VocabularyItem>> {
  @override
  Future<List<VocabularyItem>> build() async {
    final languages = await ref.watch(activeLanguagesProvider.future);
    final language = languages.firstOrNull;
    if (language == null) return const [];
    return ref.watch(vocabularyRepositoryProvider).list(language);
  }

  /// Marque [item] comme appris ou à revoir. L'affichage change aussitôt ; il
  /// est rétabli, et l'erreur relancée, si l'enregistrement échoue.
  Future<void> setLearned(
    VocabularyItem item, {
    required bool isLearned,
  }) async {
    final updated = item.copyWith(
      learnedAt: isLearned ? ref.read(clockProvider)() : null,
    );
    _replace(updated);

    try {
      await ref
          .read(vocabularyRepositoryProvider)
          .setLearned(item.id, isLearned: isLearned);
    } catch (_) {
      // Seul ce mot revient en arrière : un autre mot changé entre-temps
      // garde son nouvel état.
      if (ref.mounted) _replace(item);
      rethrow;
    }
  }

  void _replace(VocabularyItem item) {
    final words = state.value;
    if (words == null) return;
    state = AsyncData([
      for (final other in words) other.id == item.id ? item : other,
    ]);
  }
}

final vocabularyProvider =
    AsyncNotifierProvider.autoDispose<VocabularyNotifier, List<VocabularyItem>>(
      VocabularyNotifier.new,
      // Pas de nouvel essai automatique : l'écran propose « Réessayer ».
      retry: (retryCount, error) => null,
    );
