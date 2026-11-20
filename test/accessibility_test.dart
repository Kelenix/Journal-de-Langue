import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';

import 'support/fakes.dart';
import 'support/pump_app.dart';

/// Accessibilité des écrans principaux (Inc-9) : cibles tactiles assez
/// grandes, boutons nommés, contraste du texte, et très grands caractères
/// sans débordement.
void main() {
  late FakeAuthRepository auth;
  late FakeSubscriptionRepository subscriptions;
  late FakeLanguageRepository languages;
  late FakeVocabularyRepository vocabulary;
  late FakeJournalRepository journal;

  setUp(() {
    auth = FakeAuthRepository(userId: FakeAuthRepository.signedInUserId);
    subscriptions = FakeSubscriptionRepository();
    languages = FakeLanguageRepository([
      LearningLanguage.english,
    ], subscriptions);
    vocabulary = FakeVocabularyRepository([sampleWord]);
    journal = FakeJournalRepository(
      vocabulary: vocabulary,
      subscriptions: subscriptions,
    )..seedPast(sampleEntry(id: 'older', entryDate: DateTime(2026, 11, 17)));
  });

  Future<void> pump(WidgetTester tester) => pumpApp(
    tester,
    auth: auth,
    languages: languages,
    journal: journal,
    vocabulary: vocabulary,
    subscriptions: subscriptions,
  );

  Future<void> expectAccessible(WidgetTester tester, String screen) async {
    for (final (name, guideline) in [
      ('cibles Android', androidTapTargetGuideline),
      ('cibles iOS', iOSTapTargetGuideline),
      ('boutons nommés', labeledTapTargetGuideline),
      ('contraste', textContrastGuideline),
    ]) {
      await expectLater(
        tester,
        meetsGuideline(guideline),
        reason: '$screen : $name',
      );
    }
  }

  /// Onglets, puis une correction et l'écran d'offres.
  Future<void> visitScreens(
    WidgetTester tester,
    Future<void> Function(String screen) check,
  ) async {
    for (final (screen, icon) in [
      ('Journal', Icons.edit_note_outlined),
      ('Historique', Icons.history_outlined),
      ('Réviser', Icons.style_outlined),
      ('Progrès', Icons.local_fire_department_outlined),
      ('Profil', Icons.person_outline),
    ]) {
      await tapOn(tester, find.byIcon(icon));
      await check(screen);
    }

    await tapOn(tester, find.byIcon(Icons.history_outlined));
    await tapOn(tester, find.text('I has a cat.'));
    await check('Correction');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tapOn(tester, find.byIcon(Icons.person_outline));
    await tapOn(tester, find.text(english.profilePlan));
    await check('Offres');
  }

  testWidgets('les écrans principaux respectent les règles d\'accessibilité', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);

    await visitScreens(tester, (screen) => expectAccessible(tester, screen));
    semantics.dispose();
  });

  testWidgets('en mode sombre aussi', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final semantics = tester.ensureSemantics();
    await pump(tester);

    await visitScreens(tester, (screen) => expectAccessible(tester, screen));
    semantics.dispose();
  });

  testWidgets('en très grands caractères, rien ne déborde', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester);

    // Un débordement est une erreur qui fait échouer le test.
    await visitScreens(tester, (_) async {});
  });

  testWidgets('sans compte : connexion et inscription accessibles, même en '
      'très grands caractères', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(),
      languages: FakeLanguageRepository(),
    );
    await expectAccessible(tester, 'Accueil');
    await tapOn(tester, find.text(english.welcomeHaveAccount));
    await expectAccessible(tester, 'Connexion');
    await tapOn(tester, find.text(english.authNoAccount));
    await expectAccessible(tester, 'Inscription');

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    semantics.dispose();
  });
}
