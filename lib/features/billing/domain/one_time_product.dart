import 'package:freezed_annotation/freezed_annotation.dart';

import '../../languages/domain/learning_language.dart';

part 'one_time_product.freezed.dart';

/// Produits vendus à l'unité (INTAKE §4, §5.3). [id] est l'identifiant du
/// produit dans les stores et en base (`one_time_product`).
enum OneTimeProduct {
  corrections10('corrections_10'),
  corrections50('corrections_50'),
  examPack('exam_pack'),
  languagePassEnglish('language_pass_en', LearningLanguage.english),
  languagePassSpanish('language_pass_es', LearningLanguage.spanish),
  languagePassGerman('language_pass_de', LearningLanguage.german),
  languagePassFrench('language_pass_fr', LearningLanguage.french),
  removeAds('remove_ads');

  const OneTimeProduct(this.id, [this.passLanguage]);

  final String id;

  /// Langue débloquée 30 jours ; `null` pour les autres produits.
  final LearningLanguage? passLanguage;

  static OneTimeProduct? fromId(String id) =>
      values.where((product) => product.id == id).firstOrNull;
}

/// Un produit proposé à l'achat, avec le prix du store.
@freezed
abstract class ProductOffer with _$ProductOffer {
  const factory ProductOffer({
    required OneTimeProduct product,

    /// Prix déjà mis en forme par le store (« 1,99 € »).
    required String priceLabel,
  }) = _ProductOffer;
}
