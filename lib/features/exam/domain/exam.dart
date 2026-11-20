import 'package:freezed_annotation/freezed_annotation.dart';

import '../../journal/domain/journal_entry.dart';
import '../../languages/domain/learning_language.dart';

part 'exam.freezed.dart';
part 'exam.g.dart';

/// Niveaux du cadre européen proposés pour une simulation. [code] est la
/// valeur de l'énumération `exam_level` en base.
@JsonEnum(valueField: 'code')
enum ExamLevel {
  a2('A2'),
  b1('B1'),
  b2('B2'),
  c1('C1');

  const ExamLevel(this.code);

  final String code;
}

@JsonEnum(fieldRename: FieldRename.snake)
enum ExamStatus { preparing, inProgress, grading, graded }

/// Critères de la correction renforcée, notés sur 5.
enum ExamCriterion { task, coherence, vocabulary, grammar }

/// Sujet de production écrite, dans la langue apprise.
@freezed
abstract class ExamPrompt with _$ExamPrompt {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ExamPrompt({
    required String title,
    required String task,
    required int minWords,
    required int maxWords,
  }) = _ExamPrompt;

  factory ExamPrompt.fromJson(Map<String, dynamic> json) =>
      _$ExamPromptFromJson(json);
}

@freezed
abstract class CriterionScore with _$CriterionScore {
  const factory CriterionScore({
    required ExamCriterion criterion,

    /// Sur 5.
    required int score,
    required String comment,
  }) = _CriterionScore;

  factory CriterionScore.fromJson(Map<String, dynamic> json) =>
      _$CriterionScoreFromJson(json);
}

@freezed
abstract class RevisionStep with _$RevisionStep {
  const factory RevisionStep({required String title, required String details}) =
      _RevisionStep;

  factory RevisionStep.fromJson(Map<String, dynamic> json) =>
      _$RevisionStepFromJson(json);
}

/// Correction renforcée d'une rédaction.
@freezed
abstract class ExamResult with _$ExamResult {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ExamResult({
    /// Note sur 20.
    required int score,

    /// Niveau du cadre européen que montre la rédaction (de A1 à C2).
    required String levelEstimate,
    required String summary,
    required List<CriterionScore> criteria,
    required String correctedText,
    required List<CorrectionItem> items,
    required List<RevisionStep> revisionPlan,
  }) = _ExamResult;

  factory ExamResult.fromJson(Map<String, dynamic> json) =>
      _$ExamResultFromJson(json);
}

/// Simulation d'examen du Pack Examinateur (US-20).
@freezed
abstract class Exam with _$Exam {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Exam({
    required String id,
    required LearningLanguage language,
    required ExamLevel level,
    required ExamStatus status,
    required DateTime createdAt,
    ExamPrompt? prompt,

    /// Rédaction rendue, ou brouillon tant que la simulation est en cours.
    String? answer,
    ExamResult? result,
    DateTime? gradedAt,
  }) = _Exam;

  factory Exam.fromJson(Map<String, dynamic> json) => _$ExamFromJson(json);
}
