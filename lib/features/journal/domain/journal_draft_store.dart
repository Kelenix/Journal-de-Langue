import '../../languages/domain/learning_language.dart';

/// Brouillon du journal, conservé sur l'appareil pour ne rien perdre hors ligne
/// ou si l'app est fermée avant l'envoi.
abstract interface class JournalDraftStore {
  Future<String> load(String userId, LearningLanguage language);

  Future<void> save(String userId, LearningLanguage language, String text);

  /// Efface tous les brouillons de l'appareil.
  Future<void> clearAll();
}
