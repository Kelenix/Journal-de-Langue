import '../../../l10n/app_localizations.dart';
import '../domain/learning_language.dart';

String languageName(AppLocalizations l10n, LearningLanguage language) =>
    switch (language) {
      LearningLanguage.english => l10n.languageEnglish,
      LearningLanguage.spanish => l10n.languageSpanish,
      LearningLanguage.german => l10n.languageGerman,
      LearningLanguage.french => l10n.languageFrench,
    };
