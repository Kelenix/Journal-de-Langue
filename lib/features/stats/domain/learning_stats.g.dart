// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LearningStats _$LearningStatsFromJson(Map<String, dynamic> json) =>
    _LearningStats(
      isPremium: json['is_premium'] as bool,
      streakDays: (json['streak_days'] as num).toInt(),
      journals: (json['journals'] as num).toInt(),
      wordsLearned: (json['words_learned'] as num?)?.toInt(),
      wordsTotal: (json['words_total'] as num?)?.toInt(),
      mistakesByCategory:
          (json['mistakes_by_category'] as List<dynamic>?)
              ?.map((e) => CategoryCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CategoryCount>[],
      weeklyMistakeRate:
          (json['weekly_mistake_rate'] as List<dynamic>?)
              ?.map(
                (e) => WeeklyMistakeRate.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <WeeklyMistakeRate>[],
    );

Map<String, dynamic> _$LearningStatsToJson(_LearningStats instance) =>
    <String, dynamic>{
      'is_premium': instance.isPremium,
      'streak_days': instance.streakDays,
      'journals': instance.journals,
      'words_learned': instance.wordsLearned,
      'words_total': instance.wordsTotal,
      'mistakes_by_category': instance.mistakesByCategory,
      'weekly_mistake_rate': instance.weeklyMistakeRate,
    };

_CategoryCount _$CategoryCountFromJson(Map<String, dynamic> json) =>
    _CategoryCount(
      category: $enumDecode(_$ErrorCategoryEnumMap, json['category']),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$CategoryCountToJson(_CategoryCount instance) =>
    <String, dynamic>{
      'category': _$ErrorCategoryEnumMap[instance.category]!,
      'count': instance.count,
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

_WeeklyMistakeRate _$WeeklyMistakeRateFromJson(Map<String, dynamic> json) =>
    _WeeklyMistakeRate(
      weekStart: DateTime.parse(json['week_start'] as String),
      mistakesPerSentence: (json['mistakes_per_sentence'] as num).toDouble(),
    );

Map<String, dynamic> _$WeeklyMistakeRateToJson(_WeeklyMistakeRate instance) =>
    <String, dynamic>{
      'week_start': instance.weekStart.toIso8601String(),
      'mistakes_per_sentence': instance.mistakesPerSentence,
    };
