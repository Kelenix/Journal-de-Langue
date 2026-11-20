import '../../languages/domain/learning_language.dart';
import 'exam.dart';

/// Simulations d'examen de l'utilisateur connecté. Toute méthode échoue avec
/// une `Failure`.
abstract interface class ExamRepository {
  /// Simulations, la plus récente d'abord.
  Future<List<Exam>> list();

  /// Commence une simulation (un Pack Examinateur est utilisé), ou rend celle
  /// qui est déjà en cours. Peut prendre plusieurs secondes : le sujet est
  /// créé à la demande.
  Future<Exam> start({
    required LearningLanguage language,
    required ExamLevel level,
    required String uiLocale,
  });

  /// Enregistre le brouillon de la rédaction.
  Future<void> saveDraft({required String examId, required String answer});

  /// Rend la rédaction et la fait corriger. Peut prendre une minute.
  Future<Exam> submit({required String examId, required String answer});
}
