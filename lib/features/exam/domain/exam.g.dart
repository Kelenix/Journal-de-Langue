// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExamPrompt _$ExamPromptFromJson(Map<String, dynamic> json) => _ExamPrompt(
  title: json['title'] as String,
  task: json['task'] as String,
  minWords: (json['min_words'] as num).toInt(),
  maxWords: (json['max_words'] as num).toInt(),
);

Map<String, dynamic> _$ExamPromptToJson(_ExamPrompt instance) =>
    <String, dynamic>{
      'title': instance.title,
      'task': instance.task,
      'min_words': instance.minWords,
      'max_words': instance.maxWords,
    };

_CriterionScore _$CriterionScoreFromJson(Map<String, dynamic> json) =>
    _CriterionScore(
      criterion: $enumDecode(_$ExamCriterionEnumMap, json['criterion']),
      score: (json['score'] as num).toInt(),
      comment: json['comment'] as String,
    );

Map<String, dynamic> _$CriterionScoreToJson(_CriterionScore instance) =>
    <String, dynamic>{
      'criterion': _$ExamCriterionEnumMap[instance.criterion]!,
      'score': instance.score,
      'comment': instance.comment,
    };

const _$ExamCriterionEnumMap = {
  ExamCriterion.task: 'task',
  ExamCriterion.coherence: 'coherence',
  ExamCriterion.vocabulary: 'vocabulary',
  ExamCriterion.grammar: 'grammar',
};

_RevisionStep _$RevisionStepFromJson(Map<String, dynamic> json) =>
    _RevisionStep(
      title: json['title'] as String,
      details: json['details'] as String,
    );

Map<String, dynamic> _$RevisionStepToJson(_RevisionStep instance) =>
    <String, dynamic>{'title': instance.title, 'details': instance.details};

_ExamResult _$ExamResultFromJson(Map<String, dynamic> json) => _ExamResult(
  score: (json['score'] as num).toInt(),
  levelEstimate: json['level_estimate'] as String,
  summary: json['summary'] as String,
  criteria: (json['criteria'] as List<dynamic>)
      .map((e) => CriterionScore.fromJson(e as Map<String, dynamic>))
      .toList(),
  correctedText: json['corrected_text'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => CorrectionItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  revisionPlan: (json['revision_plan'] as List<dynamic>)
      .map((e) => RevisionStep.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ExamResultToJson(_ExamResult instance) =>
    <String, dynamic>{
      'score': instance.score,
      'level_estimate': instance.levelEstimate,
      'summary': instance.summary,
      'criteria': instance.criteria,
      'corrected_text': instance.correctedText,
      'items': instance.items,
      'revision_plan': instance.revisionPlan,
    };

_Exam _$ExamFromJson(Map<String, dynamic> json) => _Exam(
  id: json['id'] as String,
  language: $enumDecode(_$LearningLanguageEnumMap, json['language']),
  level: $enumDecode(_$ExamLevelEnumMap, json['level']),
  status: $enumDecode(_$ExamStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['created_at'] as String),
  prompt: json['prompt'] == null
      ? null
      : ExamPrompt.fromJson(json['prompt'] as Map<String, dynamic>),
  answer: json['answer'] as String?,
  result: json['result'] == null
      ? null
      : ExamResult.fromJson(json['result'] as Map<String, dynamic>),
  gradedAt: json['graded_at'] == null
      ? null
      : DateTime.parse(json['graded_at'] as String),
);

Map<String, dynamic> _$ExamToJson(_Exam instance) => <String, dynamic>{
  'id': instance.id,
  'language': _$LearningLanguageEnumMap[instance.language]!,
  'level': _$ExamLevelEnumMap[instance.level]!,
  'status': _$ExamStatusEnumMap[instance.status]!,
  'created_at': instance.createdAt.toIso8601String(),
  'prompt': instance.prompt,
  'answer': instance.answer,
  'result': instance.result,
  'graded_at': instance.gradedAt?.toIso8601String(),
};

const _$LearningLanguageEnumMap = {
  LearningLanguage.english: 'en',
  LearningLanguage.spanish: 'es',
  LearningLanguage.german: 'de',
  LearningLanguage.french: 'fr',
};

const _$ExamLevelEnumMap = {
  ExamLevel.a2: 'A2',
  ExamLevel.b1: 'B1',
  ExamLevel.b2: 'B2',
  ExamLevel.c1: 'C1',
};

const _$ExamStatusEnumMap = {
  ExamStatus.preparing: 'preparing',
  ExamStatus.inProgress: 'in_progress',
  ExamStatus.grading: 'grading',
  ExamStatus.graded: 'graded',
};
