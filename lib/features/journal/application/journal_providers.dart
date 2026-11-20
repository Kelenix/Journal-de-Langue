import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/uuid.dart';
import '../../auth/application/auth_providers.dart';
import '../../billing/application/billing_providers.dart';
import '../../languages/domain/learning_language.dart';
import '../../stats/application/stats_providers.dart';
import '../../vocabulary/application/vocabulary_providers.dart';
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

/// Situation du jour : ce que l'offre permet et, s'il ne reste plus de
/// correction, le journal déjà corrigé.
typedef JournalDay = ({JournalAllowance allowance, String? entryId});

final journalDayProvider = FutureProvider.autoDispose<JournalDay>(
  (ref) async {
    // Recalculé quand l'utilisateur ou son offre change.
    await ref.watch(currentUserIdProvider.future);
    await ref.watch(subscriptionProvider.future);
    final repository = ref.watch(journalRepositoryProvider);
    final today = ref.watch(clockProvider)();
    final allowance = await repository.allowance(today);
    // Le journal du jour ne sert qu'à « Voir la correction », une fois la
    // limite atteinte : rien à charger avant.
    final entryId = allowance.canCorrect
        ? null
        : await repository.entryIdOfDay(today);
    return (allowance: allowance, entryId: entryId);
  },
  // Pas de nouvel essai automatique : l'écran propose « Réessayer ».
  retry: (retryCount, error) => null,
);

/// Relit l'abonnement s'il n'a pas pu être chargé : le journal et l'historique
/// en dépendent et ne se rétablissent pas sans lui. Relu tout de suite, d'autres
/// providers l'observent (ADR-022).
Future<void> reloadFailedSubscription(WidgetRef ref) async {
  if (!ref.read(subscriptionProvider).hasError) return;
  ref.invalidate(subscriptionProvider);
  try {
    await ref.read(subscriptionProvider.future);
  } on Failure {
    // L'écran qui relance affichera l'erreur.
  }
}

/// Étendue de l'historique lisible avec l'offre, sans le charger.
final historyOverviewProvider = FutureProvider.autoDispose<HistoryOverview>((
  ref,
) async {
  // Recalculé quand l'utilisateur ou son offre change.
  await ref.watch(currentUserIdProvider.future);
  await ref.watch(subscriptionProvider.future);
  return ref.watch(journalRepositoryProvider).historyOverview();
}, retry: (retryCount, error) => null);

/// Journaux relisibles déjà chargés ; [moreFailure] est l'échec du chargement
/// de la page suivante.
typedef JournalHistory = ({
  List<JournalEntry> entries,
  bool hasMore,
  Failure? moreFailure,
});

/// Historique chargé par pages, à mesure que l'utilisateur le parcourt.
class JournalHistoryNotifier extends AsyncNotifier<JournalHistory> {
  static const pageSize = 20;

  bool _isLoadingMore = false;

  @override
  Future<JournalHistory> build() async {
    // Recalculé quand l'utilisateur ou son offre change.
    await ref.watch(currentUserIdProvider.future);
    await ref.watch(subscriptionProvider.future);
    final entries = await ref
        .watch(journalRepositoryProvider)
        .historyPage(offset: 0, limit: pageSize);
    return (
      entries: entries,
      hasMore: entries.length == pageSize,
      moreFailure: null,
    );
  }

  /// Charge la page suivante, sauf pendant un chargement ou à la fin.
  Future<void> loadMore() async {
    final history = state.value;
    if (history == null || !history.hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    if (history.moreFailure != null) {
      state = AsyncData((
        entries: history.entries,
        hasMore: true,
        moreFailure: null,
      ));
    }
    // Un rechargement pendant l'attente (journal corrigé) remplace la liste :
    // la page obtenue ne s'y ajoute pas.
    bool isOutdated() =>
        !ref.mounted || !identical(state.value?.entries, history.entries);
    try {
      final page = await ref
          .read(journalRepositoryProvider)
          .historyPage(offset: history.entries.length, limit: pageSize);
      if (isOutdated()) return;
      state = AsyncData((
        entries: [...history.entries, ...page],
        hasMore: page.length == pageSize,
        moreFailure: null,
      ));
    } on Failure catch (failure) {
      if (isOutdated()) return;
      state = AsyncData((
        entries: history.entries,
        hasMore: true,
        moreFailure: failure,
      ));
    } finally {
      _isLoadingMore = false;
    }
  }
}

final journalHistoryProvider =
    AsyncNotifierProvider.autoDispose<JournalHistoryNotifier, JournalHistory>(
      JournalHistoryNotifier.new,
      // Pas de nouvel essai automatique : l'écran propose « Réessayer ».
      retry: (retryCount, error) => null,
    );

/// Vrai dès que l'utilisateur a fait corriger un journal : avant, les offres
/// ne s'ouvrent pas d'elles-mêmes et aucun rappel ne les propose ; seul le
/// profil y mène (INTAKE §6, ADR-040). Une fonction et non un
/// provider, pour la même raison que `watchActiveSubscription` (ADR-022).
bool watchHasCorrectedJournal(WidgetRef ref) =>
    (ref.watch(historyOverviewProvider).value?.correctedEntries ?? 0) > 0;

final journalEntryProvider = FutureProvider.autoDispose
    .family<JournalEntry, String>(
      (ref, entryId) => ref.watch(journalRepositoryProvider).entry(entryId),
      retry: (retryCount, error) => null,
    );

/// Phrase d'un journal à reformuler.
typedef RewriteRequest = ({String entryId, String sentence});

final sentenceRewriteProvider = FutureProvider.autoDispose
    .family<SentenceRewrite, RewriteRequest>(
      (ref, request) => ref
          .watch(journalRepositoryProvider)
          .rewrite(entryId: request.entryId, sentence: request.sentence),
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
    // Quota déjà utilisé ailleurs (autre appareil, réponse perdue puis texte
    // modifié) : l'écran passe à la limite du jour, avec sa correction.
    if (result.error case CorrectionDeniedFailure(
      reason: CorrectionDenial.dailyLimit,
    )) {
      ref.invalidate(journalDayProvider);
    }
    if (result.hasValue) {
      // Une correction change le quota du jour, l'historique, le vocabulaire
      // et les statistiques.
      ref
        ..invalidate(journalDayProvider)
        ..invalidate(historyOverviewProvider)
        ..invalidate(journalHistoryProvider)
        ..invalidate(vocabularyProvider)
        ..invalidate(statsProvider)
        ..invalidate(walletProvider);
    }
    return result.value;
  }
}

final journalSubmissionControllerProvider =
    NotifierProvider.autoDispose<JournalSubmissionController, AsyncValue<void>>(
      JournalSubmissionController.new,
    );
