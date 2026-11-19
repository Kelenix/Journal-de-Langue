import '../../../l10n/app_localizations.dart';
import '../domain/journal_entry.dart';

String errorCategoryName(AppLocalizations l10n, ErrorCategory category) =>
    switch (category) {
      ErrorCategory.spelling => l10n.categorySpelling,
      ErrorCategory.grammar => l10n.categoryGrammar,
      ErrorCategory.conjugation => l10n.categoryConjugation,
      ErrorCategory.vocabulary => l10n.categoryVocabulary,
      ErrorCategory.register => l10n.categoryRegister,
      ErrorCategory.phrasing => l10n.categoryPhrasing,
      ErrorCategory.punctuation => l10n.categoryPunctuation,
    };
