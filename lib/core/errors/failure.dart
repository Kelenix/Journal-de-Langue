/// Erreurs attendues, exposées par les repositories à la place des exceptions
/// des bibliothèques (Supabase, réseau). L'interface en déduit un message clair.
sealed class Failure implements Exception {
  const Failure();
}

/// Pas de réseau ou serveur injoignable : l'action peut être retentée.
final class NetworkFailure extends Failure {
  const NetworkFailure();
}

final class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure();
}

final class EmailNotConfirmedFailure extends Failure {
  const EmailNotConfirmedFailure();
}

final class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure();
}

/// Code de confirmation faux ou expiré.
final class InvalidCodeFailure extends Failure {
  const InvalidCodeFailure();
}

final class RateLimitedFailure extends Failure {
  const RateLimitedFailure();
}

/// Motifs pour lesquels le serveur refuse de corriger un journal.
enum CorrectionDenial {
  dailyLimit('daily_limit'),
  tooManySentences('too_many_sentences'),
  invalidText('invalid_text'),
  languageNotActive('language_not_active'),
  invalidDate('invalid_date'),
  wrongLanguage('wrong_language'),
  contentRefused('content_refused');

  const CorrectionDenial(this.code);

  /// Valeur du champ `error` renvoyé par la fonction `correct-entry`.
  final String code;
}

/// Le serveur refuse la correction : limite de l'offre ou texte non conforme.
/// Rien n'a été débité.
final class CorrectionDeniedFailure extends Failure {
  const CorrectionDeniedFailure(this.reason);

  final CorrectionDenial reason;
}

/// La correction n'a pas abouti côté IA : rien n'a été débité, l'envoi peut
/// être retenté.
final class AiUnavailableFailure extends Failure {
  const AiUnavailableFailure();
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure();
}
