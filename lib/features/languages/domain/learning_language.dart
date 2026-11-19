import 'package:json_annotation/json_annotation.dart';

/// Langues proposées à l'apprentissage. [code] est la valeur de l'énumération
/// `language_code` en base.
@JsonEnum(valueField: 'code')
enum LearningLanguage {
  english('en'),
  spanish('es'),
  german('de'),
  french('fr');

  const LearningLanguage(this.code);

  final String code;

  static LearningLanguage fromCode(String code) =>
      values.firstWhere((language) => language.code == code);
}
