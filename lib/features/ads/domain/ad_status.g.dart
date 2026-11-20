// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ad_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdStatus _$AdStatusFromJson(Map<String, dynamic> json) => _AdStatus(
  adsEnabled: json['ads_enabled'] as bool? ?? false,
  correctionRewardAvailable:
      json['correction_reward_available'] as bool? ?? false,
  exercisesRewardAvailable:
      json['exercises_reward_available'] as bool? ?? false,
  rewardCorrections: (json['reward_corrections'] as num?)?.toInt() ?? 0,
  rewardExercises: (json['reward_exercises'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AdStatusToJson(_AdStatus instance) => <String, dynamic>{
  'ads_enabled': instance.adsEnabled,
  'correction_reward_available': instance.correctionRewardAvailable,
  'exercises_reward_available': instance.exercisesRewardAvailable,
  'reward_corrections': instance.rewardCorrections,
  'reward_exercises': instance.rewardExercises,
};
