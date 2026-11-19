import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/features/auth/application/auth_providers.dart';
import 'package:journal_de_langue/features/languages/application/language_providers.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:journal_de_langue/routing/session_gate.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeLanguageRepository languages;

  ProviderContainer createContainer() {
    final container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        languageRepositoryProvider.overrideWithValue(languages),
      ],
    );
    // Maintient le provider actif, comme le fait le routeur.
    container.listen(sessionGateProvider, (_, _) {});
    return container;
  }

  Future<SessionGate> settledGate(ProviderContainer container) async {
    await pumpEventQueue();
    return container.read(sessionGateProvider);
  }

  setUp(() {
    auth = FakeAuthRepository();
    languages = FakeLanguageRepository();
  });

  test('est en chargement tant que la session n\'est pas connue', () {
    final container = createContainer();

    expect(container.read(sessionGateProvider), SessionGate.loading);
  });

  test('sans session : déconnecté', () async {
    final container = createContainer();

    expect(await settledGate(container), SessionGate.signedOut);
  });

  test('connecté sans langue active : choix de la langue requis', () async {
    auth = FakeAuthRepository(userId: FakeAuthRepository.signedInUserId);
    final container = createContainer();

    expect(await settledGate(container), SessionGate.needsLanguage);
  });

  test('connecté avec une langue active : prêt', () async {
    auth = FakeAuthRepository(userId: FakeAuthRepository.signedInUserId);
    languages = FakeLanguageRepository([LearningLanguage.english]);
    final container = createContainer();

    expect(await settledGate(container), SessionGate.ready);
  });

  test('langues impossibles à charger : échec', () async {
    auth = FakeAuthRepository(userId: FakeAuthRepository.signedInUserId);
    languages.failure = const NetworkFailure();
    final container = createContainer();

    expect(await settledGate(container), SessionGate.failed);
  });

  test(
    'suit la connexion, le choix de la langue puis la déconnexion',
    () async {
      final container = createContainer();
      expect(await settledGate(container), SessionGate.signedOut);

      await auth.signIn(email: 'lea@example.test', password: 'motdepasse');
      expect(await settledGate(container), SessionGate.needsLanguage);

      await container
          .read(activeLanguagesProvider.notifier)
          .activate(LearningLanguage.german);
      expect(await settledGate(container), SessionGate.ready);

      await auth.signOut();
      expect(await settledGate(container), SessionGate.signedOut);
    },
  );
}
