import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'failure.dart';

/// Convertit toute erreur d'accès aux données en [Failure].
Failure mapError(Object error, StackTrace stackTrace) {
  final failure = switch (error) {
    Failure() => error,
    AuthRetryableFetchException() => const NetworkFailure(),
    SocketException() ||
    TimeoutException() ||
    TlsException() => const NetworkFailure(),
    AuthWeakPasswordException() => const WeakPasswordFailure(),
    AuthException(code: 'weak_password') => const WeakPasswordFailure(),
    AuthException(code: 'invalid_credentials') =>
      const InvalidCredentialsFailure(),
    AuthException(code: 'email_not_confirmed') =>
      const EmailNotConfirmedFailure(),
    AuthException(code: 'otp_expired') => const InvalidCodeFailure(),
    AuthException(
      code: 'over_email_send_rate_limit' || 'over_request_rate_limit',
    ) =>
      const RateLimitedFailure(),
    FunctionException(status: _aiUnavailableStatus) =>
      const AiUnavailableFailure(),
    FunctionException(details: {'error': final String code}) =>
      _correctionDenial(code),
    _ => const UnexpectedFailure(),
  };

  if (failure is UnexpectedFailure) {
    developer.log(
      'Erreur non prévue',
      name: 'data',
      error: error,
      stackTrace: stackTrace,
    );
  }
  return failure;
}

const _aiUnavailableStatus = 503;

/// Refus renvoyé par la fonction `correct-entry`, d'après son champ `error`.
Failure _correctionDenial(String code) {
  for (final reason in CorrectionDenial.values) {
    if (reason.code == code) return CorrectionDeniedFailure(reason);
  }
  return const UnexpectedFailure();
}

/// Exécute [action] en ne laissant sortir que des [Failure].
Future<T> guardFailures<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (error, stackTrace) {
    throw mapError(error, stackTrace);
  }
}
