// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CorrectionItem _$CorrectionItemFromJson(Map<String, dynamic> json) =>
    _CorrectionItem(
      original: json['original'] as String,
      corrected: json['corrected'] as String,
      category: $enumDecode(_$ErrorCategoryEnumMap, json['category']),
      explanation: json['explanation'] as String,
    );

Map<String, dynamic> _$CorrectionItemToJson(_CorrectionItem instance) =>
    <String, dynamic>{
      'original': instance.original,
      'corrected': instance.corrected,
      'category': _$ErrorCategoryEnumMap[instance.category]!,
      'explanation': instance.explanation,
    };

const _$ErrorCategoryEnumMap = {
  ErrorCategory.spelling: 'spelling',
  ErrorCategory.grammar: 'grammar',
  ErrorCategory.conjugation: 'conjugation',
  ErrorCategory.vocabulary: 'vocabulary',
  ErrorCategory.register: 'register',
  ErrorCategory.phrasing: 'phrasing',
  ErrorCategory.punctuation: 'punctuation',
};

_JournalEntry _$JournalEntryFromJson(Map<String, dynamic> json) =>
    _JournalEntry(
      id: json['id'] as String,
      language: $enumDecode(_$LearningLanguageEnumMap, json['language']),
      entryDate: DateTime.parse(json['entry_date'] as String),
      originalText: json['original_text'] as String,
      correctedText: json['corrected_text'] as String,
      items: (json['correction_items'] as List<dynamic>)
          .map((e) => CorrectionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$JournalEntryToJson(_JournalEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'language': _$LearningLanguageEnumMap[instance.language]!,
      'entry_date': instance.entryDate.toIso8601String(),
      'original_text': instance.originalText,
      'corrected_text': instance.correctedText,
      'correction_items': instance.items,
    };

const _$LearningLanguageEnumMap = {
  LearningLanguage.english: 'en',
  LearningLanguage.spanish: 'es',
  LearningLanguage.german: 'de',
  LearningLanguage.french: 'fr',
};

_JournalAllowance _$JournalAllowanceFromJson(Map<String, dynamic> json) =>
    _JournalAllowance(
      maxSentences: (json['max_sentences'] as num).toInt(),
      maxCharacters: (json['max_characters'] as num).toInt(),
      correctionsLeft: (json['corrections_left'] as num).toInt(),
    );

Map<String, dynamic> _$JournalAllowanceToJson(_JournalAllowance instance) =>
    <String, dynamic>{
      'max_sentences': instance.maxSentences,
      'max_characters': instance.maxCharacters,
      'corrections_left': instance.correctionsLeft,
    };
