import '../../languages/domain/learning_language.dart';
import 'journal_entry.dart';

/// Journaux de l'utilisateur connecté. Toute méthode échoue avec une `Failure`.
abstract interface class JournalRepository {
  /// Limites de l'offre et corrections restantes pour [day].
  Future<JournalAllowance> allowance(DateTime day);

  /// Identifiant du dernier journal corrigé de [day], s'il existe.
  Future<String?> entryIdOfDay(DateTime day);

  Future<JournalEntry> entry(String id);

  /// Page de journaux corrigés que l'offre permet de relire, du plus récent au
  /// plus ancien, sans leur vocabulaire.
  Future<List<JournalEntry>> historyPage({
    required int offset,
    required int limit,
  });

  /// Tous les journaux corrigés et lisibles en [language], depuis [firstDay]
  /// s'il est donné, du plus récent au plus ancien.
  Future<List<JournalEntry>> entriesSince(
    LearningLanguage language, {
    DateTime? firstDay,
  });

  Future<HistoryOverview> historyOverview();

  /// Reformule [sentence], tirée de la version corrigée du journal [entryId]
  /// (Premium).
  Future<SentenceRewrite> rewrite({
    required String entryId,
    required String sentence,
  });

  /// Fait corriger [text]. Rejouer le même [idempotencyKey] après une coupure
  /// rend la correction déjà faite sans consommer une seconde fois le quota.
  Future<JournalEntry> submit({
    required String text,
    required LearningLanguage language,
    required String uiLocale,
    required DateTime day,
    required String idempotencyKey,
  });
}
