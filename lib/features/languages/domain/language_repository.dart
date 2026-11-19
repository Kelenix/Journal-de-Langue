import 'learning_language.dart';

/// Langues pratiquées par l'utilisateur connecté. Échoue avec une `Failure`.
abstract interface class LanguageRepository {
  /// Langues utilisables avec l'offre, la langue en cours d'abord.
  Future<List<LearningLanguage>> activeLanguages();

  /// Fait de [language] la langue en cours. En gratuit, elle remplace la
  /// langue active ; en Premium, elle s'ajoute aux autres dans la limite de
  /// l'offre (sinon `LanguageLimitFailure`).
  Future<void> activate(LearningLanguage language);

  /// Retire [language] des langues pratiquées. Ses journaux sont conservés.
  Future<void> deactivate(LearningLanguage language);
}
