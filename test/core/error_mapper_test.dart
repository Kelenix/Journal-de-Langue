import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/error_mapper.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  Failure map(Object error) => mapError(error, StackTrace.empty);

  group('mapError', () {
    test('reconnaît les coupures réseau', () {
      expect(map(AuthRetryableFetchException()), isA<NetworkFailure>());
      expect(map(const SocketException('hors ligne')), isA<NetworkFailure>());
      expect(map(TimeoutException('trop long')), isA<NetworkFailure>());
    });

    test('traduit les codes d\'erreur du serveur d\'authentification', () {
      Failure fromCode(String code) => map(AuthException('x', code: code));

      expect(fromCode('invalid_credentials'), isA<InvalidCredentialsFailure>());
      expect(fromCode('email_not_confirmed'), isA<EmailNotConfirmedFailure>());
      expect(fromCode('weak_password'), isA<WeakPasswordFailure>());
      expect(fromCode('otp_expired'), isA<InvalidCodeFailure>());
      expect(fromCode('over_email_send_rate_limit'), isA<RateLimitedFailure>());
      expect(fromCode('over_request_rate_limit'), isA<RateLimitedFailure>());
    });

    test('laisse passer une Failure déjà typée', () {
      const failure = InvalidCodeFailure();

      expect(map(failure), same(failure));
    });

    test('classe le reste comme erreur inattendue', () {
      expect(
        map(const AuthException('x', code: 'inconnu')),
        isA<UnexpectedFailure>(),
      );
      expect(map(StateError('bug')), isA<UnexpectedFailure>());
    });

    test('traduit les réponses de la fonction de correction', () {
      Failure fromFunction(int status, Object? details) =>
          map(FunctionException(status: status, details: details));

      expect(
        fromFunction(403, {'error': 'daily_limit'}),
        isA<CorrectionDeniedFailure>().having(
          (f) => f.reason,
          'reason',
          CorrectionDenial.dailyLimit,
        ),
      );
      expect(
        fromFunction(403, {'error': 'too_many_sentences', 'max_sentences': 7}),
        isA<CorrectionDeniedFailure>().having(
          (f) => f.reason,
          'reason',
          CorrectionDenial.tooManySentences,
        ),
      );
      expect(
        fromFunction(422, {'error': 'wrong_language'}),
        isA<CorrectionDeniedFailure>(),
      );
      expect(
        fromFunction(503, {'error': 'ai_unavailable'}),
        isA<AiUnavailableFailure>(),
      );
      expect(
        fromFunction(500, {'error': 'internal'}),
        isA<UnexpectedFailure>(),
      );
      expect(fromFunction(401, 'non autorisé'), isA<UnexpectedFailure>());
    });

    test('traduit les refus des fonctions réservées à Premium', () {
      Failure fromFunction(String code) =>
          map(FunctionException(status: 403, details: {'error': code}));

      expect(fromFunction('premium_required'), isA<PremiumRequiredFailure>());
      expect(fromFunction('rewrite_limit'), isA<UsageLimitFailure>());
      expect(fromFunction('no_exam_credit'), isA<NoExamCreditFailure>());
    });

    test('une demande encore en cours peut être retentée', () {
      Failure fromConflict(String code) =>
          map(FunctionException(status: 409, details: {'error': code}));

      expect(
        fromConflict('correction_in_progress'),
        isA<RequestInProgressFailure>(),
      );
      expect(fromConflict('exam_busy'), isA<RequestInProgressFailure>());
    });

    test('trop de tentatives sans résultat : refus expliqué', () {
      expect(
        map(
          const FunctionException(
            status: 403,
            details: {'error': 'too_many_attempts'},
          ),
        ),
        isA<CorrectionDeniedFailure>().having(
          (f) => f.reason,
          'reason',
          CorrectionDenial.tooManyAttempts,
        ),
      );
    });
  });

  group('guardFailures', () {
    test('retourne la valeur en cas de succès', () async {
      expect(await guardFailures(() async => 42), 42);
    });

    test('ne laisse sortir que des Failure', () {
      expect(
        guardFailures<void>(() async => throw const SocketException('x')),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
