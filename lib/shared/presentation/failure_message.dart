import '../../core/errors/failure.dart';
import '../../l10n/app_localizations.dart';

/// Message affiché à l'utilisateur pour [error] : clair, sans détail technique.
String failureMessage(AppLocalizations l10n, Object error) => switch (error) {
  NetworkFailure() => l10n.errorNetwork,
  InvalidCredentialsFailure() => l10n.errorInvalidCredentials,
  EmailNotConfirmedFailure() => l10n.errorEmailNotConfirmed,
  WeakPasswordFailure() => l10n.errorWeakPassword,
  InvalidCodeFailure() => l10n.errorInvalidCode,
  RateLimitedFailure() => l10n.errorRateLimited,
  AiUnavailableFailure() => l10n.errorAiUnavailable,
  CorrectionDeniedFailure(:final reason) => switch (reason) {
    CorrectionDenial.dailyLimit => l10n.journalDailyLimitReached,
    CorrectionDenial.tooManySentences => l10n.errorTooManySentences,
    CorrectionDenial.invalidText => l10n.errorInvalidText,
    CorrectionDenial.languageNotActive => l10n.errorLanguageNotActive,
    CorrectionDenial.invalidDate => l10n.errorInvalidDate,
    CorrectionDenial.wrongLanguage => l10n.errorWrongLanguage,
    CorrectionDenial.contentRefused => l10n.errorContentRefused,
  },
  _ => l10n.errorUnexpected,
};
