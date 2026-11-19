// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocabulary_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VocabularyItem _$VocabularyItemFromJson(Map<String, dynamic> json) =>
    _VocabularyItem(
      id: json['id'] as String,
      term: json['term'] as String,
      translation: json['translation'] as String,
      example: json['example'] as String,
      learnedAt: json['learned_at'] == null
          ? null
          : DateTime.parse(json['learned_at'] as String),
    );

Map<String, dynamic> _$VocabularyItemToJson(_VocabularyItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'term': instance.term,
      'translation': instance.translation,
      'example': instance.example,
      'learned_at': instance.learnedAt?.toIso8601String(),
    };
