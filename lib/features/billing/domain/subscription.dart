import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

/// Offres Premium. Valeurs de l'énumération `plan` en base.
enum SubscriptionPlan { weekly, monthly, annual }

/// Abonnement connu du serveur pour l'utilisateur connecté.
@freezed
abstract class Subscription with _$Subscription {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Subscription({
    required SubscriptionPlan plan,

    /// L'abonnement donne ses droits tant que cette date n'est pas passée.
    required DateTime expiresAt,
    @Default(false) bool inTrial,
  }) = _Subscription;

  const Subscription._();

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  bool isActiveAt(DateTime moment) => expiresAt.isAfter(moment);
}
