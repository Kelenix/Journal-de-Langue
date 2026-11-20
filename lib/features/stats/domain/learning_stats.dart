import 'package:freezed_annotation/freezed_annotation.dart';

import '../../journal/domain/journal_entry.dart';

part 'learning_stats.freezed.dart';
part 'learning_stats.g.dart';

/// Progrès de l'utilisateur dans une langue (US-16). La série est visible avec
/// toutes les offres ; le reste est réservé à Premium.
@freezed
abstract class LearningStats with _$LearningStats {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory LearningStats({
    required bool isPremium,

    /// Jours consécutifs avec un journal corrigé, toutes langues confondues,
    /// jusqu'à aujourd'hui ou hier.
    required int streakDays,

    /// Journaux corrigés dans cette langue.
    required int journals,

    /// Jours de la semaine en cours (du lundi à aujourd'hui) avec un journal
    /// corrigé, toutes langues confondues.
    @Default(<DateTime>[]) List<DateTime> weekDays,
    int? wordsLearned,
    int? wordsTotal,

    /// Du type de faute le plus fréquent au moins fréquent.
    @Default(<CategoryCount>[]) List<CategoryCount> mistakesByCategory,

    /// Semaines des 8 dernières, de la plus ancienne à la plus récente.
    @Default(<WeeklyMistakeRate>[]) List<WeeklyMistakeRate> weeklyMistakeRate,
  }) = _LearningStats;

  factory LearningStats.fromJson(Map<String, dynamic> json) =>
      _$LearningStatsFromJson(json);
}

@freezed
abstract class CategoryCount with _$CategoryCount {
  const factory CategoryCount({
    required ErrorCategory category,
    required int count,
  }) = _CategoryCount;

  factory CategoryCount.fromJson(Map<String, dynamic> json) =>
      _$CategoryCountFromJson(json);
}

@freezed
abstract class WeeklyMistakeRate with _$WeeklyMistakeRate {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory WeeklyMistakeRate({
    /// Lundi de la semaine.
    required DateTime weekStart,
    required double mistakesPerSentence,
  }) = _WeeklyMistakeRate;

  factory WeeklyMistakeRate.fromJson(Map<String, dynamic> json) =>
      _$WeeklyMistakeRateFromJson(json);
}
