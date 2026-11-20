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
      weekDays:
          (json['week_days'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          const <DateTime>[],
      wordsLearned: (json['words_learned'] as num?)?.toInt(),
      wordsTotal: (json['words_total'] as num?)?.toInt(),
      mistakesByCategory:
          (json['mistakes_by_category'] as List<dynamic>?)
              ?.map((e) => CategoryCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CategoryCount>[],
      weeklyJournals:
          (json['weekly_journals'] as List<dynamic>?)
              ?.map((e) => WeeklyJournals.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <WeeklyJournals>[],
    );

Map<String, dynamic> _$LearningStatsToJson(_LearningStats instance) =>
    <String, dynamic>{
      'is_premium': instance.isPremium,
      'streak_days': instance.streakDays,
      'journals': instance.journals,
      'week_days': instance.weekDays.map((e) => e.toIso8601String()).toList(),
      'words_learned': instance.wordsLearned,
      'words_total': instance.wordsTotal,
      'mistakes_by_category': instance.mistakesByCategory,
      'weekly_journals': instance.weeklyJournals,
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

_WeeklyJournals _$WeeklyJournalsFromJson(Map<String, dynamic> json) =>
    _WeeklyJournals(
      weekStart: DateTime.parse(json['week_start'] as String),
      journals: (json['journals'] as num).toInt(),
    );

Map<String, dynamic> _$WeeklyJournalsToJson(_WeeklyJournals instance) =>
    <String, dynamic>{
      'week_start': instance.weekStart.toIso8601String(),
      'journals': instance.journals,
    };
