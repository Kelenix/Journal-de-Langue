import '../../languages/domain/learning_language.dart';
import 'vocabulary_item.dart';

/// Vocabulaire de l'utilisateur connecté. Toute méthode échoue avec une `Failure`.
abstract interface class VocabularyRepository {
  /// Tous les mots proposés pour [language], du plus récent au plus ancien.
  Future<List<VocabularyItem>> list(LearningLanguage language);

  Future<void> setLearned(String itemId, {required bool isLearned});
}
