import '../../languages/domain/learning_language.dart';
import 'journal_entry.dart';

/// Journaux de l'utilisateur connecté. Toute méthode échoue avec une `Failure`.
abstract interface class JournalRepository {
  /// Limites de l'offre et corrections restantes pour [day].
  Future<JournalAllowance> allowance(DateTime day);

  /// Dernier journal corrigé de [day], s'il existe.
  Future<JournalEntry?> entryOfDay(DateTime day);

  Future<JournalEntry> entry(String id);

  /// Journaux corrigés que l'offre permet de relire, du plus récent au plus
  /// ancien.
  Future<List<JournalEntry>> recentEntries();

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
