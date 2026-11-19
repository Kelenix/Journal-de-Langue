import 'learning_language.dart';

/// Langues pratiquées par l'utilisateur connecté. Échoue avec une `Failure`.
abstract interface class LanguageRepository {
  Future<List<LearningLanguage>> activeLanguages();

  /// Active [language]. Le serveur applique la limite de l'offre : en gratuit,
  /// elle remplace la langue active.
  Future<void> activate(LearningLanguage language);
}
