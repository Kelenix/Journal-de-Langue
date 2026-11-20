import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';

import 'support/fakes.dart';
import 'support/pump_app.dart';

/// Non-régression (ADR-022) : des données modifiées pendant qu'un onglet ou un
/// écran est masqué doivent se recharger sans erreur quand il redevient
/// visible. Avec flutter_riverpod 3.3.2, un provider observé par un autre et
/// recalculé à ce moment-là lève une assertion.
void main() {
  late FakeAuthRepository auth;
  late FakeLanguageRepository languages;
  late FakeVocabularyRepository vocabulary;
  late FakeSubscriptionRepository subscriptions;
  late FakeBillingRepository billing;
  late FakeJournalRepository journal;

  setUp(() {
    auth = FakeAuthRepository(userId: FakeAuthRepository.signedInUserId);
    languages = FakeLanguageRepository([LearningLanguage.english]);
    vocabulary = FakeVocabularyRepository();
    subscriptions = FakeSubscriptionRepository();
    billing = FakeBillingRepository(subscriptions);
    journal = FakeJournalRepository(
      vocabulary: vocabulary,
      subscriptions: subscriptions,
    );
  });

  Future<void> pump(WidgetTester tester) => pumpApp(
    tester,
    auth: auth,
    languages: languages,
    journal: journal,
    vocabulary: vocabulary,
    subscriptions: subscriptions,
    billing: billing,
  );

  Future<void> openTab(WidgetTester tester, IconData icon) =>
      tapOn(tester, find.byIcon(icon));

  /// Ouvre chaque onglet une fois : tous sont construits, puis masqués.
  Future<void> visitEveryTab(WidgetTester tester) async {
    for (final icon in [
      Icons.history_outlined,
      Icons.style_outlined,
      Icons.local_fire_department_outlined,
      Icons.person_outline,
      Icons.edit_note_outlined,
    ]) {
      await openTab(tester, icon);
    }
  }

  Future<void> correctJournal(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'I has a cat.');
    await tester.pump();
    await tapOn(
      tester,
      find.widgetWithText(FilledButton, english.journalSubmit),
    );
    await tapOn(tester, find.text(english.correctionDone));
  }

  testWidgets('après une correction, les onglets déjà ouverts se mettent à '
      'jour', (tester) async {
    await pump(tester);
    await visitEveryTab(tester);

    await correctJournal(tester);

    await openTab(tester, Icons.history_outlined);
    expect(find.text('I has a cat.'), findsOneWidget);

    await openTab(tester, Icons.style_outlined);
    expect(find.text(english.reviewCardOf(1, 1)), findsOneWidget);

    // L'offre payante peut maintenant être proposée depuis le profil.
    await openTab(tester, Icons.person_outline);
    await tapOn(tester, find.text(english.profilePlan));
    expect(find.text(english.paywallTitle), findsOneWidget);
  });

  testWidgets('après un achat, les onglets déjà ouverts reflètent Premium', (
    tester,
  ) async {
    journal
      ..seedPast(sampleEntry(id: 'past', entryDate: DateTime(2026, 11, 18)))
      ..lockedEntries = 2;
    await pump(tester);
    await visitEveryTab(tester);
    await correctJournal(tester);

    await tapOn(tester, find.text(english.paywallDiscover));
    await tapOn(tester, find.text(english.paywallStartTrial(3)));

    expect(find.text(english.journalSentenceCount(0, 40)), findsOneWidget);

    await openTab(tester, Icons.history_outlined);
    expect(find.text(english.historyUnlock), findsNothing);

    await openTab(tester, Icons.person_outline);
    expect(
      find.textContaining(english.profilePlanPremium(english.planAnnual)),
      findsOneWidget,
    );
  });

  testWidgets('après un changement de langue, le journal et le vocabulaire '
      'suivent', (tester) async {
    vocabulary.items.add(sampleWord);
    await pump(tester);
    await visitEveryTab(tester);

    await openTab(tester, Icons.person_outline);
    await tapOn(tester, find.text(english.profileLanguages(1)));
    await tapOn(tester, find.text(english.languageGerman));

    await openTab(tester, Icons.edit_note_outlined);
    expect(find.text(english.languageGerman), findsOneWidget);

    await openTab(tester, Icons.style_outlined);
    expect(find.text(english.reviewCardOf(1, 1)), findsOneWidget);
  });
}
