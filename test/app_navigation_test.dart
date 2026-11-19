import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:journal_de_langue/l10n/app_localizations.dart';

import 'support/fakes.dart';
import 'support/pump_app.dart';

void main() {
  Future<void> pumpReadyApp(WidgetTester tester) => pumpApp(
    tester,
    auth: FakeAuthRepository(userId: FakeAuthRepository.signedInUserId),
    languages: FakeLanguageRepository([LearningLanguage.spanish]),
  );

  Future<void> openTab(WidgetTester tester, IconData icon) async {
    await tester.tap(find.byIcon(icon));
    await tester.pumpAndSettle();
  }

  testWidgets('un utilisateur prêt arrive sur le journal de sa langue', (
    tester,
  ) async {
    await pumpReadyApp(tester);

    expect(find.text(english.journalEmpty), findsOneWidget);
    expect(find.text(english.languageSpanish), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });

  testWidgets('chaque onglet affiche son écran', (tester) async {
    await pumpReadyApp(tester);

    await openTab(tester, Icons.history_outlined);
    expect(find.text(english.historyEmpty), findsOneWidget);

    await openTab(tester, Icons.style_outlined);
    expect(find.text(english.reviewEmpty), findsOneWidget);

    await openTab(tester, Icons.local_fire_department_outlined);
    expect(find.text(english.progressEmpty), findsOneWidget);

    await openTab(tester, Icons.person_outline);
    expect(find.text(english.profileDeleteAccount), findsOneWidget);
  });

  testWidgets('s\'affiche en français sur un téléphone en français', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await pumpReadyApp(tester);

    final french = lookupAppLocalizations(const Locale('fr'));
    expect(find.text(french.journalEmpty), findsOneWidget);
  });
}
