import 'package:freezed_annotation/freezed_annotation.dart';

part 'ad_status.freezed.dart';
part 'ad_status.g.dart';

/// Récompenses d'une vidéo vue en entier (US-23). [code] est la valeur de
/// l'énumération `ad_reward_kind` en base, transmise à AdMob avec la vidéo.
enum AdRewardKind {
  correction('correction'),
  exercises('exercises');

  const AdRewardKind(this.code);

  final String code;
}

/// Publicités et récompenses de l'utilisateur connecté, décidées par le
/// serveur : offre gratuite, pas d'achat « sans publicité », inscrit depuis
/// plus de 14 jours (US-22).
@freezed
abstract class AdStatus with _$AdStatus {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AdStatus({
    @Default(false) bool adsEnabled,

    /// Vrai si aucune correction n'a encore été obtenue par vidéo aujourd'hui.
    @Default(false) bool correctionRewardAvailable,
    @Default(false) bool exercisesRewardAvailable,

    /// Unités obtenues par des vidéos et pas encore utilisées.
    @Default(0) int rewardCorrections,
    @Default(0) int rewardExercises,
  }) = _AdStatus;

  const AdStatus._();

  factory AdStatus.fromJson(Map<String, dynamic> json) =>
      _$AdStatusFromJson(json);

  bool canWatchFor(AdRewardKind kind) =>
      adsEnabled &&
      switch (kind) {
        AdRewardKind.correction => correctionRewardAvailable,
        AdRewardKind.exercises => exercisesRewardAvailable,
      };

  int rewardsLeft(AdRewardKind kind) => switch (kind) {
    AdRewardKind.correction => rewardCorrections,
    AdRewardKind.exercises => rewardExercises,
  };
}
