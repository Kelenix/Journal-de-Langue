import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client_provider.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/uuid.dart';
import '../../auth/application/auth_providers.dart';
import '../../languages/domain/learning_language.dart';
import '../data/secure_journal_draft_store.dart';
import '../data/supabase_journal_repository.dart';
import '../domain/journal_draft_store.dart';
import '../domain/journal_entry.dart';
import '../domain/journal_repository.dart';

final journalRepositoryProvider = Provider<JournalRepository>(
  (ref) => SupabaseJournalRepository(ref.watch(supabaseClientProvider)),
);

final journalDraftStoreProvider = Provider<JournalDraftStore>(
  (ref) => const SecureJournalDraftStore(),
);

/// Situation du jour : ce que l'offre permet et le journal déjà corrigé.
typedef JournalDay = ({JournalAllowance allowance, JournalEntry? entry});

final journalDayProvider = FutureProvider.autoDispose<JournalDay>(
  (ref) async {
    // Recalculé quand l'utilisateur change.
    await ref.watch(currentUserIdProvider.future);
    final repository = ref.watch(journalRepositoryProvider);
    final today = ref.watch(clockProvider)();
    // L'un après l'autre : attendus ensemble, une erreur serait enveloppée et
    // l'écran ne saurait plus dire laquelle.
    final allowance = await repository.allowance(today);
    final entry = await repository.entryOfDay(today);
    return (allowance: allowance, entry: entry);
  },
  // Pas de nouvel essai automatique : l'écran propose « Réessayer ».
  retry: (retryCount, error) => null,
);

final journalEntryProvider = FutureProvider.autoDispose
    .family<JournalEntry, String>(
      (ref, entryId) => ref.watch(journalRepositoryProvider).entry(entryId),
      retry: (retryCount, error) => null,
    );

/// Envoi du journal en cours de rédaction.
class JournalSubmissionController extends Notifier<AsyncValue<void>> {
  String? _attemptText;
  String? _attemptKey;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Retourne le journal corrigé, ou `null` si l'envoi a échoué (voir `state`).
  Future<JournalEntry?> submit({
    required String text,
    required LearningLanguage language,
    required String uiLocale,
  }) async {
    // Une nouvelle tentative du même texte réutilise sa clé : si la première a
    // abouti côté serveur malgré une coupure, la correction est retrouvée au
    // lieu d'être refusée par le quota du jour.
    if (_attemptText != text) {
      _attemptText = text;
      _attemptKey = newUuid();
    }

    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(journalRepositoryProvider)
          .submit(
            text: text,
            language: language,
            uiLocale: uiLocale,
            day: ref.read(clockProvider)(),
            idempotencyKey: _attemptKey!,
          ),
    );
    if (!ref.mounted) return result.value;

    state = result;
    if (result.hasValue) ref.invalidate(journalDayProvider);
    return result.value;
  }
}

final journalSubmissionControllerProvider =
    NotifierProvider.autoDispose<JournalSubmissionController, AsyncValue<void>>(
      JournalSubmissionController.new,
    );
