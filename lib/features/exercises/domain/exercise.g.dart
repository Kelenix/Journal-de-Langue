// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Exercise _$ExerciseFromJson(Map<String, dynamic> json) => _Exercise(
  id: json['id'] as String,
  question: json['question'] as String,
  options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$ExerciseToJson(_Exercise instance) => <String, dynamic>{
  'id': instance.id,
  'question': instance.question,
  'options': instance.options,
};

_ExerciseFeedback _$ExerciseFeedbackFromJson(Map<String, dynamic> json) =>
    _ExerciseFeedback(
      isCorrect: json['is_correct'] as bool,
      answerIndex: (json['answer_index'] as num).toInt(),
      explanation: json['explanation'] as String,
      left: (json['left'] as num).toInt(),
    );

Map<String, dynamic> _$ExerciseFeedbackToJson(_ExerciseFeedback instance) =>
    <String, dynamic>{
      'is_correct': instance.isCorrect,
      'answer_index': instance.answerIndex,
      'explanation': instance.explanation,
      'left': instance.left,
    };
