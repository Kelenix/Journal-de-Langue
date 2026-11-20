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
      level:
          $enumDecodeNullable(_$CorrectionLevelEnumMap, json['level']) ??
          CorrectionLevel.basic,
      items: (json['correction_items'] as List<dynamic>)
          .map((e) => CorrectionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      vocabulary:
          (json['vocabulary_items'] as List<dynamic>?)
              ?.map((e) => VocabularyItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <VocabularyItem>[],
    );

Map<String, dynamic> _$JournalEntryToJson(_JournalEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'language': _$LearningLanguageEnumMap[instance.language]!,
      'entry_date': instance.entryDate.toIso8601String(),
      'original_text': instance.originalText,
      'corrected_text': instance.correctedText,
      'level': _$CorrectionLevelEnumMap[instance.level]!,
      'correction_items': instance.items,
      'vocabulary_items': instance.vocabulary,
    };

const _$LearningLanguageEnumMap = {
  LearningLanguage.english: 'en',
  LearningLanguage.spanish: 'es',
  LearningLanguage.german: 'de',
  LearningLanguage.french: 'fr',
};

const _$CorrectionLevelEnumMap = {
  CorrectionLevel.basic: 'basic',
  CorrectionLevel.advanced: 'advanced',
};

_SentenceRewrite _$SentenceRewriteFromJson(Map<String, dynamic> json) =>
    _SentenceRewrite(
      polite: json['polite'] as String,
      casual: json['casual'] as String,
      professional: json['professional'] as String,
    );

Map<String, dynamic> _$SentenceRewriteToJson(_SentenceRewrite instance) =>
    <String, dynamic>{
      'polite': instance.polite,
      'casual': instance.casual,
      'professional': instance.professional,
    };

_JournalAllowance _$JournalAllowanceFromJson(Map<String, dynamic> json) =>
    _JournalAllowance(
      maxSentences: (json['max_sentences'] as num).toInt(),
      maxCharacters: (json['max_characters'] as num).toInt(),
      correctionsLeft: (json['corrections_left'] as num).toInt(),
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      rewardCorrections: (json['reward_corrections'] as num?)?.toInt() ?? 0,
      plan: $enumDecodeNullable(_$SubscriptionPlanEnumMap, json['plan']),
    );

Map<String, dynamic> _$JournalAllowanceToJson(_JournalAllowance instance) =>
    <String, dynamic>{
      'max_sentences': instance.maxSentences,
      'max_characters': instance.maxCharacters,
      'corrections_left': instance.correctionsLeft,
      'credits': instance.credits,
      'reward_corrections': instance.rewardCorrections,
      'plan': _$SubscriptionPlanEnumMap[instance.plan],
    };

const _$SubscriptionPlanEnumMap = {
  SubscriptionPlan.weekly: 'weekly',
  SubscriptionPlan.monthly: 'monthly',
  SubscriptionPlan.annual: 'annual',
};

_HistoryOverview _$HistoryOverviewFromJson(Map<String, dynamic> json) =>
    _HistoryOverview(
      historyDays: (json['history_days'] as num?)?.toInt(),
      lockedEntries: (json['locked_entries'] as num).toInt(),
      correctedEntries: (json['corrected_entries'] as num).toInt(),
    );

Map<String, dynamic> _$HistoryOverviewToJson(_HistoryOverview instance) =>
    <String, dynamic>{
      'history_days': instance.historyDays,
      'locked_entries': instance.lockedEntries,
      'corrected_entries': instance.correctedEntries,
    };
