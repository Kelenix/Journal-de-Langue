// Tests d'intégration des repositories de compte contre le Supabase local (Docker).
// Prérequis : `supabase start` et `env/dev.json`.
// Lancer : flutter test test_integration
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/features/auth/data/supabase_auth_repository.dart';
import 'package:journal_de_langue/features/languages/data/supabase_language_repository.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/backend.dart';

void main() {
  late SupabaseClient client;
  late SupabaseAuthRepository auth;
  late SupabaseLanguageRepository languages;
  late String email;

  setUp(() {
    client = createTestClient();
    auth = SupabaseAuthRepository(client);
    languages = SupabaseLanguageRepository(client);
    email = newTestEmail();
  });

  tearDown(() => deleteAccountAndDispose(client));

  test('inscription : connexion impossible avant confirmation, puis code '
      'faux refusé, puis code reçu accepté', () async {
    await auth.signUp(email: email, password: testPassword);

    await expectLater(
      auth.signIn(email: email, password: testPassword),
      throwsA(isA<EmailNotConfirmedFailure>()),
    );

    final code = await latestEmailCode(email, emailCount: 1);
    final wrongCode = code == '000000' ? '111111' : '000000';
    await expectLater(
      auth.confirmSignUp(email: email, code: wrongCode),
      throwsA(isA<InvalidCodeFailure>()),
    );

    await auth.confirmSignUp(email: email, code: code);

    expect(await auth.watchUserId().first, isNotNull);
  });

  test('langues : aucune au départ, puis une seule active à la fois', () async {
    await signUpConfirmed(client, email);

    expect(await languages.activeLanguages(), isEmpty);

    await languages.activate(LearningLanguage.english);
    expect(await languages.activeLanguages(), [LearningLanguage.english]);

    await languages.activate(LearningLanguage.german);
    expect(await languages.activeLanguages(), [LearningLanguage.german]);
  });

  test('connexion : mauvais mot de passe refusé, bon mot de passe accepté, '
      'langue retrouvée', () async {
    await signUpConfirmed(client, email);
    await languages.activate(LearningLanguage.spanish);
    await auth.signOut();
    expect(await auth.watchUserId().first, isNull);

    await expectLater(
      auth.signIn(email: email, password: 'mauvais-mot-de-passe'),
      throwsA(isA<InvalidCredentialsFailure>()),
    );

    await auth.signIn(email: email, password: testPassword);
    expect(await languages.activeLanguages(), [LearningLanguage.spanish]);
  });

  test(
    'mot de passe oublié : le code reçu permet d\'en choisir un nouveau',
    () async {
      const newPassword = 'motdepasse-nouveau';
      await signUpConfirmed(client, email);
      await auth.signOut();
      // Le serveur espace les e-mails d'un même compte (max_frequency = 1s).
      await Future<void>.delayed(const Duration(seconds: 2));

      await auth.requestPasswordReset(email);
      await auth.resetPassword(
        email: email,
        code: await latestEmailCode(email, emailCount: 2),
        newPassword: newPassword,
      );
      expect(await auth.watchUserId().first, isNotNull);

      await auth.signOut();
      await expectLater(
        auth.signIn(email: email, password: testPassword),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
      await auth.signIn(email: email, password: newPassword);
    },
  );

  test('suppression : le compte et ses données disparaissent', () async {
    await signUpConfirmed(client, email);
    await languages.activate(LearningLanguage.french);

    await auth.deleteAccount();

    expect(await auth.watchUserId().first, isNull);
    await expectLater(
      auth.signIn(email: email, password: testPassword),
      throwsA(isA<InvalidCredentialsFailure>()),
    );
  });

  test('sans session, le serveur refuse la lecture des langues', () async {
    await expectLater(languages.activeLanguages(), throwsA(isA<Failure>()));
  });
}
