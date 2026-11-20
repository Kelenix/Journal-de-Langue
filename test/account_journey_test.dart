import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';

import 'support/fakes.dart';
import 'support/pump_app.dart';

/// Parcours de compte de bout en bout sur des données en mémoire (US-01 à US-03).
void main() {
  const email = 'lea@example.test';
  const password = 'motdepasse';

  late FakeAuthRepository auth;
  late FakeLanguageRepository languages;

  setUp(() {
    auth = FakeAuthRepository();
    languages = FakeLanguageRepository();
  });

  Future<void> enter(WidgetTester tester, String label, String text) =>
      tester.enterText(find.widgetWithText(TextFormField, label), text);

  Future<void> tapText(WidgetTester tester, String text) =>
      tapOn(tester, find.text(text));

  Future<void> tapButton(WidgetTester tester, String label) =>
      tapOn(tester, find.widgetWithText(FilledButton, label));

  /// Depuis l'accueil, première page sans compte.
  Future<void> openSignIn(WidgetTester tester) =>
      tapText(tester, english.welcomeHaveAccount);

  Future<void> openSignUp(WidgetTester tester) =>
      tapButton(tester, english.authSignUpAction);

  testWidgets('sans session, l\'app ouvre l\'accueil, sans offre, puis la '
      'connexion', (tester) async {
    await pumpApp(tester, auth: auth, languages: languages);

    expect(find.text(english.welcomeTitle), findsOneWidget);
    expect(find.text(english.welcomeFeatureCorrect), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await openSignIn(tester);

    expect(find.text(english.authSignInAction), findsWidgets);
  });

  testWidgets('l\'inscription et la connexion se remplacent ; le retour '
      'ramène à l\'accueil', (tester) async {
    await pumpApp(tester, auth: auth, languages: languages);
    await openSignUp(tester);

    await tapText(tester, english.authHaveAccount);
    expect(find.text(english.authForgotPassword), findsOneWidget);

    await tapOn(tester, find.byType(BackButton));
    expect(find.text(english.welcomeTitle), findsOneWidget);
  });

  testWidgets('inscription, code, choix de la langue, puis journal', (
    tester,
  ) async {
    await pumpApp(tester, auth: auth, languages: languages);

    await openSignUp(tester);
    await enter(tester, english.authEmailLabel, email);
    await enter(tester, english.authPasswordLabel, password);
    await tapButton(tester, english.authSignUpAction);

    expect(find.text(english.verifyInstructions(email)), findsOneWidget);

    await enter(tester, english.verifyCodeLabel, '123456');
    await tapButton(tester, english.verifyAction);

    expect(find.text(english.onboardingTitle), findsOneWidget);

    await tapText(tester, english.languageGerman);

    expect(find.text(english.journalEmpty), findsOneWidget);
    expect(find.text(english.languageGerman), findsOneWidget);
    expect(auth.calls, ['signUp $email', 'confirmSignUp $email 123456']);
  });

  testWidgets('l\'inscription refuse un e-mail invalide et un mot de passe '
      'trop court sans appeler le serveur', (tester) async {
    await pumpApp(tester, auth: auth, languages: languages);
    await openSignUp(tester);

    await enter(tester, english.authEmailLabel, 'pas-un-email');
    await enter(tester, english.authPasswordLabel, 'court');
    await tapButton(tester, english.authSignUpAction);

    expect(find.text(english.authEmailInvalid), findsOneWidget);
    expect(find.text(english.authPasswordTooShort), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('des identifiants erronés affichent un message qui ne dit pas '
      'si le compte existe', (tester) async {
    auth.failure = const InvalidCredentialsFailure();
    await pumpApp(tester, auth: auth, languages: languages);
    await openSignIn(tester);

    await enter(tester, english.authEmailLabel, email);
    await enter(tester, english.authPasswordLabel, password);
    await tapButton(tester, english.authSignInAction);

    expect(find.text(english.errorInvalidCredentials), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  /// Connexion avec un e-mail jamais confirmé, puis saisie du code proposée.
  Future<void> openCodeEntry(WidgetTester tester) async {
    auth.failure = const EmailNotConfirmedFailure();
    await pumpApp(tester, auth: auth, languages: languages);
    await openSignIn(tester);

    await enter(tester, english.authEmailLabel, email);
    await enter(tester, english.authPasswordLabel, password);
    await tapButton(tester, english.authSignInAction);
    await tapText(tester, english.verifyEnterCode);
  }

  testWidgets('un e-mail non confirmé propose de saisir le code', (
    tester,
  ) async {
    await openCodeEntry(tester);

    expect(find.text(english.verifyInstructions(email)), findsOneWidget);
  });

  testWidgets('le code de confirmation peut être renvoyé', (tester) async {
    await openCodeEntry(tester);
    auth.failure = null;

    await tapText(tester, english.verifyResend);

    expect(auth.calls, contains('resendSignUpCode $email'));
    expect(find.text(english.verifyResent), findsOneWidget);
  });

  testWidgets('mot de passe oublié : code puis nouveau mot de passe', (
    tester,
  ) async {
    languages = FakeLanguageRepository([LearningLanguage.english]);
    await pumpApp(tester, auth: auth, languages: languages);
    await openSignIn(tester);

    await tapText(tester, english.authForgotPassword);
    await enter(tester, english.authEmailLabel, email);
    await tapButton(tester, english.forgotSendCode);

    expect(find.text(english.forgotCodeSent(email)), findsOneWidget);

    await enter(tester, english.verifyCodeLabel, '654321');
    await enter(tester, english.authNewPasswordLabel, 'nouveaumotdepasse');
    await tapButton(tester, english.forgotResetAction);

    expect(find.text(english.journalEmpty), findsOneWidget);
    expect(auth.calls, [
      'requestPasswordReset $email',
      'resetPassword $email 654321',
    ]);
  });

  group('profil', () {
    setUp(() {
      auth = FakeAuthRepository(userId: FakeAuthRepository.signedInUserId);
      languages = FakeLanguageRepository([LearningLanguage.english]);
    });

    Future<void> openProfile(WidgetTester tester) async {
      await pumpApp(tester, auth: auth, languages: languages);
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
    }

    testWidgets('changer de langue remplace la langue active', (tester) async {
      await openProfile(tester);

      await tapText(tester, english.profileLanguagesTitle);
      await tapText(tester, english.languageFrench);

      expect(find.text(english.profileChangeLanguageNote), findsNothing);
      expect(find.text(english.languageFrench), findsOneWidget);
      expect(await languages.activeLanguages(), [LearningLanguage.french]);
    });

    testWidgets('se déconnecter ramène à l\'accueil', (tester) async {
      await openProfile(tester);

      await tapText(tester, english.profileSignOut);

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text(english.welcomeHaveAccount), findsOneWidget);
    });

    testWidgets('supprimer son compte exige deux confirmations', (
      tester,
    ) async {
      await openProfile(tester);

      await tapText(tester, english.profileDeleteAccount);
      expect(find.text(english.deleteAccountBody), findsOneWidget);
      await tapText(tester, english.actionContinue);
      expect(find.text(english.deleteAccountFinalBody), findsOneWidget);
      expect(auth.calls, isEmpty);

      await tapText(tester, english.deleteAccountConfirm);

      expect(auth.calls, ['deleteAccount']);
      expect(find.text(english.welcomeHaveAccount), findsOneWidget);
    });

    testWidgets('annuler la suppression ne supprime rien', (tester) async {
      await openProfile(tester);

      await tapText(tester, english.profileDeleteAccount);
      await tapText(tester, english.actionCancel);

      expect(auth.calls, isEmpty);
      expect(find.text(english.profileDeleteAccount), findsOneWidget);
    });

    testWidgets('une suppression en échec garde l\'utilisateur connecté et '
        'l\'en informe', (tester) async {
      await openProfile(tester);
      auth.failure = const NetworkFailure();

      await tapText(tester, english.profileDeleteAccount);
      await tapText(tester, english.actionContinue);
      await tapText(tester, english.deleteAccountConfirm);

      expect(find.text(english.errorNetwork), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  testWidgets('un compte qui ne se charge pas propose de réessayer', (
    tester,
  ) async {
    auth = FakeAuthRepository(userId: FakeAuthRepository.signedInUserId);
    languages = FakeLanguageRepository([LearningLanguage.english])
      ..failure = const NetworkFailure();
    await pumpApp(tester, auth: auth, languages: languages);

    expect(find.text(english.startupError), findsOneWidget);

    languages.failure = null;
    await tapText(tester, english.actionRetry);

    expect(find.text(english.journalEmpty), findsOneWidget);
  });
}
