import 'package:freezed_annotation/freezed_annotation.dart';

import '../../languages/domain/learning_language.dart';

part 'wallet.freezed.dart';
part 'wallet.g.dart';

/// Ce que l'utilisateur a acheté à l'unité et pas encore utilisé, tel que le
/// serveur le connaît.
@freezed
abstract class Wallet with _$Wallet {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Wallet({
    @Default(0) int correctionCredits,
    @Default(0) int examCredits,
    @Default(false) bool adsRemoved,

    /// Accès de 30 jours en cours, du plus proche de sa fin au plus lointain.
    @Default(<LanguagePass>[]) List<LanguagePass> languagePasses,
  }) = _Wallet;

  const Wallet._();

  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);

  bool get isEmpty =>
      correctionCredits == 0 &&
      examCredits == 0 &&
      !adsRemoved &&
      languagePasses.isEmpty;
}

@freezed
abstract class LanguagePass with _$LanguagePass {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory LanguagePass({
    required LearningLanguage language,
    required DateTime expiresAt,
  }) = _LanguagePass;

  factory LanguagePass.fromJson(Map<String, dynamic> json) =>
      _$LanguagePassFromJson(json);
}
