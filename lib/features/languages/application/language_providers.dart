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

/// Langues de l'utilisateur connecté, la langue en cours d'abord ; vide s'il
/// n'est pas connecté. L'offre fixe leur nombre : relues après un achat
/// (`PaywallController`) ou au démarrage, pas à chaque changement d'offre, pour
/// ne pas renvoyer la navigation vers l'écran de démarrage (`sessionGate`).
class ActiveLanguagesNotifier extends AsyncNotifier<List<LearningLanguage>> {
  @override
  Future<List<LearningLanguage>> build() async {
    final userId = await ref.watch(currentUserIdProvider.future);
    if (userId == null) return const [];
    return ref.watch(languageRepositoryProvider).activeLanguages();
  }

  Future<void> activate(LearningLanguage language) async {
    await ref.read(languageRepositoryProvider).activate(language);
    await reload();
  }

  Future<void> deactivate(LearningLanguage language) async {
    await ref.read(languageRepositoryProvider).deactivate(language);
    await reload();
  }

  /// Relit les langues tout de suite, d'autres providers en dépendent
  /// (ADR-022). Sans repasser par le chargement : si la lecture échoue, la
  /// liste précédente reste et l'erreur revient à l'appelant, au lieu de
  /// renvoyer la navigation vers l'écran de démarrage (`sessionGate`).
  Future<void> reload() async {
    state = AsyncData(
      await ref.read(languageRepositoryProvider).activeLanguages(),
    );
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

  Future<bool> remove(LearningLanguage language) => run(
    () => ref.read(activeLanguagesProvider.notifier).deactivate(language),
  );
}

typedef _LanguageSelectionControllerProvider =
    NotifierProvider<LanguageSelectionController, AsyncValue<void>>;

_LanguageSelectionControllerProvider _languageSelectionController() =>
    NotifierProvider.autoDispose<LanguageSelectionController, AsyncValue<void>>(
      LanguageSelectionController.new,
    );

/// Choix des langues (onboarding, profil). Le journal a le sien : un échec sur
/// l'un ne s'affiche pas sur l'autre.
final languageSelectionControllerProvider = _languageSelectionController();
final journalLanguageControllerProvider = _languageSelectionController();
