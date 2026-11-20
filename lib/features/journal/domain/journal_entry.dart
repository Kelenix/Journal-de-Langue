import 'package:freezed_annotation/freezed_annotation.dart';

import '../../billing/domain/subscription.dart';
import '../../languages/domain/learning_language.dart';
import '../../vocabulary/domain/vocabulary_item.dart';

part 'journal_entry.freezed.dart';
part 'journal_entry.g.dart';

/// Valeurs de l'énumération `error_category` en base.
enum ErrorCategory {
  spelling,
  grammar,
  conjugation,
  vocabulary,
  register,
  phrasing,
  punctuation,
}

/// Profondeur de la correction : avancée pour les abonnés Premium (registre,
/// formulation naturelle, explications détaillées).
enum CorrectionLevel { basic, advanced }

/// Une faute relevée dans un journal.
@freezed
abstract class CorrectionItem with _$CorrectionItem {
  const factory CorrectionItem({
    /// Fragment fautif, tel qu'écrit par l'utilisateur.
    required String original,
    required String corrected,
    required ErrorCategory category,
    required String explanation,
  }) = _CorrectionItem;

  factory CorrectionItem.fromJson(Map<String, dynamic> json) =>
      _$CorrectionItemFromJson(json);
}

/// Un journal corrigé.
@freezed
abstract class JournalEntry with _$JournalEntry {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory JournalEntry({
    required String id,
    required LearningLanguage language,
    required DateTime entryDate,
    required String originalText,
    required String correctedText,
    @Default(CorrectionLevel.basic) CorrectionLevel level,
    @JsonKey(name: 'correction_items') required List<CorrectionItem> items,

    /// Mots à réviser tirés de ce journal.
    @JsonKey(name: 'vocabulary_items')
    @Default(<VocabularyItem>[])
    List<VocabularyItem> vocabulary,
  }) = _JournalEntry;

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryFromJson(json);
}

/// Une phrase reformulée en trois registres (Premium).
@freezed
abstract class SentenceRewrite with _$SentenceRewrite {
  const factory SentenceRewrite({
    required String polite,
    required String casual,
    required String professional,
  }) = _SentenceRewrite;

  factory SentenceRewrite.fromJson(Map<String, dynamic> json) =>
      _$SentenceRewriteFromJson(json);
}

/// Ce que l'offre de l'utilisateur lui permet aujourd'hui.
@freezed
abstract class JournalAllowance with _$JournalAllowance {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory JournalAllowance({
    required int maxSentences,
    required int maxCharacters,
    required int correctionsLeft,

    /// Corrections achetées à l'unité, utilisées une fois le quota du jour
    /// épuisé (US-18).
    @Default(0) int credits,

    /// Corrections offertes par des vidéos, utilisées après les crédits
    /// (US-23).
    @Default(0) int rewardCorrections,

    /// Offre Premium en cours ; `null` avec l'offre gratuite.
    SubscriptionPlan? plan,
  }) = _JournalAllowance;

  factory JournalAllowance.fromJson(Map<String, dynamic> json) =>
      _$JournalAllowanceFromJson(json);
}

extension JournalAllowanceUse on JournalAllowance {
  /// Une correction reste possible aujourd'hui : quota de l'offre, crédit
  /// acheté ou correction offerte par une vidéo.
  bool get canCorrect =>
      correctionsLeft > 0 || credits > 0 || rewardCorrections > 0;
}

/// Étendue de l'historique lisible avec l'offre de l'utilisateur.
@freezed
abstract class HistoryOverview with _$HistoryOverview {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory HistoryOverview({
    /// Nombre de jours d'historique lisibles ; `null` si l'offre donne accès à
    /// tout l'historique.
    required int? historyDays,

    /// Journaux plus anciens, conservés mais non lisibles avec cette offre.
    required int lockedEntries,

    /// Tous les journaux corrigés, lisibles ou non.
    required int correctedEntries,
  }) = _HistoryOverview;

  factory HistoryOverview.fromJson(Map<String, dynamic> json) =>
      _$HistoryOverviewFromJson(json);
}
