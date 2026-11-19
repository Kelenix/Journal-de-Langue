import 'package:freezed_annotation/freezed_annotation.dart';

part 'vocabulary_item.freezed.dart';
part 'vocabulary_item.g.dart';

/// Un mot ou une expression à réviser, tiré d'un journal corrigé.
@freezed
abstract class VocabularyItem with _$VocabularyItem {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory VocabularyItem({
    required String id,

    /// Dans la langue apprise.
    required String term,

    /// Dans la langue de l'interface.
    required String translation,

    /// Phrase d'exemple dans la langue apprise.
    required String example,

    /// Null tant que le mot est à réviser.
    DateTime? learnedAt,
  }) = _VocabularyItem;

  factory VocabularyItem.fromJson(Map<String, dynamic> json) =>
      _$VocabularyItemFromJson(json);
}
