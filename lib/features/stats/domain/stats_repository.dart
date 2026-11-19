import '../../languages/domain/learning_language.dart';
import 'learning_stats.dart';

/// Statistiques de l'utilisateur connecté. Échoue avec une `Failure`.
abstract interface class StatsRepository {
  /// Progrès dans [language], au jour [day] de l'appareil.
  Future<LearningStats> get({
    required LearningLanguage language,
    required DateTime day,
  });
}
