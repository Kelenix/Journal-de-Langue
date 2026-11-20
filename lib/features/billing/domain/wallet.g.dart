// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Wallet _$WalletFromJson(Map<String, dynamic> json) => _Wallet(
  correctionCredits: (json['correction_credits'] as num?)?.toInt() ?? 0,
  examCredits: (json['exam_credits'] as num?)?.toInt() ?? 0,
  adsRemoved: json['ads_removed'] as bool? ?? false,
  languagePasses:
      (json['language_passes'] as List<dynamic>?)
          ?.map((e) => LanguagePass.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <LanguagePass>[],
);

Map<String, dynamic> _$WalletToJson(_Wallet instance) => <String, dynamic>{
  'correction_credits': instance.correctionCredits,
  'exam_credits': instance.examCredits,
  'ads_removed': instance.adsRemoved,
  'language_passes': instance.languagePasses,
};

_LanguagePass _$LanguagePassFromJson(Map<String, dynamic> json) =>
    _LanguagePass(
      language: $enumDecode(_$LearningLanguageEnumMap, json['language']),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );

Map<String, dynamic> _$LanguagePassToJson(_LanguagePass instance) =>
    <String, dynamic>{
      'language': _$LearningLanguageEnumMap[instance.language]!,
      'expires_at': instance.expiresAt.toIso8601String(),
    };

const _$LearningLanguageEnumMap = {
  LearningLanguage.english: 'en',
  LearningLanguage.spanish: 'es',
  LearningLanguage.german: 'de',
  LearningLanguage.french: 'fr',
};
