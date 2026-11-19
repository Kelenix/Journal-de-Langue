// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Subscription _$SubscriptionFromJson(Map<String, dynamic> json) =>
    _Subscription(
      plan: $enumDecode(_$SubscriptionPlanEnumMap, json['plan']),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      inTrial: json['in_trial'] as bool? ?? false,
    );

Map<String, dynamic> _$SubscriptionToJson(_Subscription instance) =>
    <String, dynamic>{
      'plan': _$SubscriptionPlanEnumMap[instance.plan]!,
      'expires_at': instance.expiresAt.toIso8601String(),
      'in_trial': instance.inTrial,
    };

const _$SubscriptionPlanEnumMap = {
  SubscriptionPlan.weekly: 'weekly',
  SubscriptionPlan.monthly: 'monthly',
  SubscriptionPlan.annual: 'annual',
};
