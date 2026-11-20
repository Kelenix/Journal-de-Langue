import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:journal_de_langue/features/legal/domain/legal_document.dart';

import 'support/fakes.dart';
import 'support/pump_app.dart';

/// Conditions d'utilisation et politique de confidentialité (Inc-9).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('le Markdown simple des textes légaux est découpé en blocs', () {
    expect(
      parseLegalText(
        '# Titre\n\nIntro sur\ndeux lignes.\n\n## Section\n- un\n- deux\nFin.\n',
      ),
      [
        (kind: LegalBlockKind.title, text: 'Titre'),
        (kind: LegalBlockKind.paragraph, text: 'Intro sur deux lignes.'),
        (kind: LegalBlockKind.section, text: 'Section'),
        (kind: LegalBlockKind.listItem, text: 'un'),
        (kind: LegalBlockKind.listItem, text: 'deux'),
        (kind: LegalBlockKind.paragraph, text: 'Fin.'),
      ],
    );
  });

  test('chaque texte existe en français et en anglais, avec les mêmes '
      'sections', () async {
    for (final document in LegalDocument.values) {
      Future<List<String>> sections(String language) async => [
        for (final block in parseLegalText(
          await rootBundle.loadString(document.assetPath(language)),
        ))
          if (block.kind == LegalBlockKind.section) block.text,
      ];

      final french = await sections('fr');
      expect(french, isNotEmpty, reason: document.name);
      expect(
        (await sections('en')).length,
        french.length,
        reason: document.name,
      );
    }
  });

  /// Ouvre le lien [title] jusqu'à voir [expected] : le texte est lu pour de
  /// vrai dans les fichiers de l'app, il faut laisser passer du temps réel.
  Future<void> openLegal(
    WidgetTester tester,
    String title, {
    required String expected,
  }) async {
    // Pas de pumpAndSettle : l'indicateur de chargement tourne tant que le
    // texte n'est pas lu.
    final link = find.text(title).last;
    await tester.ensureVisible(link);
    await tester.pump();
    await tester.tap(link);
    for (
      var attempt = 0;
      attempt < 50 && find.text(expected).evaluate().isEmpty;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('les textes légaux se lisent depuis l\'inscription, sans '
      'compte', (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(),
      languages: FakeLanguageRepository(),
    );
    // Depuis l'accueil, « Créer mon compte ».
    await tapOn(
      tester,
      find.widgetWithText(FilledButton, english.authSignUpAction),
    );

    expect(find.text(english.legalSignUpNotice), findsOneWidget);

    const heading = 'Who is responsible for your data';
    await openLegal(tester, english.legalPrivacyTitle, expected: heading);

    expect(find.text(heading), findsOneWidget);
  });

  testWidgets('le profil donne accès aux conditions d\'utilisation', (
    tester,
  ) async {
    final subscriptions = FakeSubscriptionRepository();
    await pumpApp(
      tester,
      auth: FakeAuthRepository(userId: FakeAuthRepository.signedInUserId),
      languages: FakeLanguageRepository([
        LearningLanguage.english,
      ], subscriptions),
      subscriptions: subscriptions,
    );
    await tapOn(tester, find.byIcon(Icons.person_outline));

    const heading = 'The service';
    await openLegal(tester, english.legalTermsTitle, expected: heading);

    expect(find.text(heading), findsOneWidget);
  });
}
