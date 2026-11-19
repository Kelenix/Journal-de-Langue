import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../../shared/application/action_controller.dart';
import '../../auth/application/auth_providers.dart';
import '../data/supabase_language_repository.dart';
import '../domain/language_repository.dart';
import '../domain/learning_language.dart';

final languageRepositoryProvider = Provider<LanguageRepository>(
  (ref) => SupabaseLanguageRepository(ref.watch(supabaseClientProvider)),
);

/// Langues actives de l'utilisateur connecté ; vide s'il n'est pas connecté.
class ActiveLanguagesNotifier extends AsyncNotifier<List<LearningLanguage>> {
  @override
  Future<List<LearningLanguage>> build() async {
    final userId = await ref.watch(currentUserIdProvider.future);
    if (userId == null) return const [];
    return ref.watch(languageRepositoryProvider).activeLanguages();
  }

  Future<void> activate(LearningLanguage language) async {
    await ref.read(languageRepositoryProvider).activate(language);
    ref.invalidateSelf();
    await future;
  }
}

final activeLanguagesProvider =
    AsyncNotifierProvider<ActiveLanguagesNotifier, List<LearningLanguage>>(
      ActiveLanguagesNotifier.new,
      // Pas de nouvel essai automatique : l'écran propose « Réessayer ».
      retry: (retryCount, error) => null,
    );

class LanguageSelectionController extends ActionController {
  Future<bool> select(LearningLanguage language) =>
      run(() => ref.read(activeLanguagesProvider.notifier).activate(language));
}

final languageSelectionControllerProvider =
    NotifierProvider.autoDispose<LanguageSelectionController, AsyncValue<void>>(
      LanguageSelectionController.new,
    );
