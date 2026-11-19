import 'package:freezed_annotation/freezed_annotation.dart';

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
    @JsonKey(name: 'correction_items') required List<CorrectionItem> items,

    /// Mots à réviser tirés de ce journal.
    @JsonKey(name: 'vocabulary_items')
    @Default(<VocabularyItem>[])
    List<VocabularyItem> vocabulary,
  }) = _JournalEntry;

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryFromJson(json);
}

/// Ce que l'offre de l'utilisateur lui permet aujourd'hui.
@freezed
abstract class JournalAllowance with _$JournalAllowance {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory JournalAllowance({
    required int maxSentences,
    required int maxCharacters,
    required int correctionsLeft,
  }) = _JournalAllowance;

  factory JournalAllowance.fromJson(Map<String, dynamic> json) =>
      _$JournalAllowanceFromJson(json);
}

/// Étendue de l'historique lisible avec l'offre de l'utilisateur.
@freezed
abstract class HistoryOverview with _$HistoryOverview {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory HistoryOverview({
    /// Nombre de jours d'historique lisibles.
    required int historyDays,

    /// Journaux plus anciens, conservés mais non lisibles avec cette offre.
    required int lockedEntries,
  }) = _HistoryOverview;

  factory HistoryOverview.fromJson(Map<String, dynamic> json) =>
      _$HistoryOverviewFromJson(json);
}
