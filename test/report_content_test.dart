import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/errors/failure.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:journal_de_langue/features/reports/domain/content_report_repository.dart';

import 'support/fakes.dart';
import 'support/pump_app.dart';

/// Signalement d'un contenu produit par l'IA, sans quitter l'app (Inc-9).
void main() {
  late FakeSubscriptionRepository subscriptions;
  late FakeJournalRepository journal;
  late FakeContentReportRepository reports;

  setUp(() {
    subscriptions = FakeSubscriptionRepository();
    journal = FakeJournalRepository(subscriptions: subscriptions)
      ..seedPast(sampleEntry(id: 'entry-7', entryDate: DateTime(2026, 11, 18)));
    reports = FakeContentReportRepository();
  });

  Future<void> openCorrection(WidgetTester tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(userId: FakeAuthRepository.signedInUserId),
      languages: FakeLanguageRepository([
        LearningLanguage.english,
      ], subscriptions),
      journal: journal,
      subscriptions: subscriptions,
      reports: reports,
    );
    await tapOn(tester, find.byIcon(Icons.schedule_outlined));
    await tapOn(tester, find.text('I has a cat.'));
  }

  testWidgets('une correction se signale avec un commentaire', (tester) async {
    await openCorrection(tester);

    await tapOn(tester, find.byTooltip(english.reportAction));
    await tester.enterText(find.byType(TextField), '  Explication fausse.  ');
    await tapOn(tester, find.text(english.reportSend));

    expect(reports.reports, [
      (
        content: ReportedContent.correction,
        targetId: 'entry-7',
        comment: 'Explication fausse.',
      ),
    ]);
    expect(find.text(english.reportThanks), findsOneWidget);
  });

  testWidgets('annuler n\'envoie rien', (tester) async {
    await openCorrection(tester);

    await tapOn(tester, find.byTooltip(english.reportAction));
    await tapOn(tester, find.text(english.actionCancel));

    expect(reports.reports, isEmpty);
  });

  testWidgets('un envoi qui échoue est expliqué', (tester) async {
    reports.failure = const NetworkFailure();
    await openCorrection(tester);

    await tapOn(tester, find.byTooltip(english.reportAction));
    await tapOn(tester, find.text(english.reportSend));

    expect(find.text(english.errorNetwork), findsOneWidget);
  });
}
