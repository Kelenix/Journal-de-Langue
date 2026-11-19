import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/features/billing/domain/subscription.dart';
import 'package:journal_de_langue/features/export/domain/export_period.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:journal_de_langue/features/voice/domain/voice_service.dart';

import 'support/fakes.dart';
import 'support/pump_app.dart';

/// Dictée, lecture à voix haute et export PDF, réservés à Premium
/// (US-15, US-17).
void main() {
  late FakeAuthRepository auth;
  late FakeLanguageRepository languages;
  late FakeSubscriptionRepository subscriptions;
  late FakeJournalRepository journal;
  late FakeVoiceService voice;
  late List<({String fileName, int size})> sharedPdfs;

  setUp(() {
    auth = FakeAuthRepository(userId: FakeAuthRepository.signedInUserId);
    subscriptions = FakeSubscriptionRepository();
    languages = FakeLanguageRepository([
      LearningLanguage.english,
    ], subscriptions);
    journal = FakeJournalRepository(subscriptions: subscriptions);
    voice = FakeVoiceService();
    sharedPdfs = [];
  });

  void subscribe() => subscriptions.subscription = Subscription(
    plan: SubscriptionPlan.monthly,
    expiresAt: FakeSubscriptionRepository.farFuture,
  );

  Future<void> pump(WidgetTester tester) => pumpApp(
    tester,
    auth: auth,
    languages: languages,
    journal: journal,
    subscriptions: subscriptions,
    voice: voice,
    sharedPdfs: sharedPdfs,
  );

  Future<void> tapText(WidgetTester tester, String text) =>
      tapOn(tester, find.text(text));

  String editorText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  /// Ouvre, depuis l'historique, la correction d'un journal déjà corrigé.
  Future<void> openCorrection(WidgetTester tester) async {
    journal.seedPast(sampleEntry());
    await pump(tester);
    await tapOn(tester, find.byIcon(Icons.history_outlined));
    await tapText(tester, 'I has a cat.');
  }

  group('dictée', () {
    testWidgets('gratuit : pas de dictée ni de lecture', (tester) async {
      await openCorrection(tester);
      expect(find.byTooltip(english.voiceListen), findsNothing);

      await tapText(tester, english.correctionDone);
      await tapOn(tester, find.byIcon(Icons.edit_note_outlined));

      expect(find.byTooltip(english.voiceDictate), findsNothing);
    });

    testWidgets('Premium : le texte dicté s\'ajoute après ce qui est écrit', (
      tester,
    ) async {
      subscribe();
      await pump(tester);
      await tester.enterText(find.byType(TextField), 'Hello.');
      await tester.pump();

      await tapOn(tester, find.byTooltip(english.voiceDictate));

      expect(editorText(tester), 'Hello. I has a dog.');
      expect(find.text(english.journalSentenceCount(2, 40)), findsOneWidget);
      expect(find.byTooltip(english.voiceStopDictation), findsOneWidget);

      await tapOn(tester, find.byTooltip(english.voiceStopDictation));

      expect(find.byTooltip(english.voiceDictate), findsOneWidget);
    });

    testWidgets('micro refusé : l\'app l\'explique et le clavier reste '
        'disponible', (tester) async {
      subscribe();
      voice.dictation = DictationStart.permissionDenied;
      await pump(tester);

      await tapOn(tester, find.byTooltip(english.voiceDictate));

      expect(find.text(english.voicePermissionDenied), findsOneWidget);
      expect(editorText(tester), isEmpty);
      expect(find.byTooltip(english.voiceDictate), findsOneWidget);
    });

    testWidgets('langue non reconnue par le téléphone : la dictée disparaît', (
      tester,
    ) async {
      subscribe();
      voice.dictation = DictationStart.unavailable;
      await pump(tester);

      await tapOn(tester, find.byTooltip(english.voiceDictate));

      expect(find.text(english.voiceDictationUnavailable), findsOneWidget);
      expect(find.byTooltip(english.voiceDictate), findsNothing);
    });
  });

  group('lecture à voix haute', () {
    testWidgets('Premium : la version corrigée est lue dans la langue du '
        'journal', (tester) async {
      subscribe();
      await openCorrection(tester);

      await tapOn(tester, find.byTooltip(english.voiceListen));

      expect(voice.spoken, [('I have a cat.', LearningLanguage.english)]);
    });

    testWidgets('sans voix pour la langue sur le téléphone, pas de lecture', (
      tester,
    ) async {
      subscribe();
      voice.speakable = {};
      await openCorrection(tester);

      expect(find.byTooltip(english.voiceListen), findsNothing);
    });
  });

  group('export PDF', () {
    Future<void> openReview(WidgetTester tester) async {
      await pump(tester);
      await tapOn(tester, find.byIcon(Icons.style_outlined));
    }

    testWidgets('gratuit : pas d\'export', (tester) async {
      journal.seedPast(sampleEntry());
      await openReview(tester);

      expect(find.byTooltip(english.exportTitle), findsNothing);
    });

    testWidgets('Premium : les révisions de la période sont mises en PDF et '
        'partagées', (tester) async {
      subscribe();
      journal.seedPast(sampleEntry());
      await openReview(tester);

      await tapOn(tester, find.byTooltip(english.exportTitle));
      // Polices et document sont produits hors de l'horloge simulée du test.
      await tester.runAsync(() => tapText(tester, english.exportLastWeek));
      await tester.pumpAndSettle();

      expect(sharedPdfs, hasLength(1));
      expect(sharedPdfs.single.fileName, 'journal-de-langue-en-2026-11-19.pdf');
      expect(sharedPdfs.single.size, greaterThan(1000));
    });

    testWidgets('rien sur la période : l\'app le dit, sans partager', (
      tester,
    ) async {
      subscribe();
      journal.seedPast(sampleEntry(entryDate: DateTime(2026, 10, 1)));
      await openReview(tester);

      await tapOn(tester, find.byTooltip(english.exportTitle));
      await tapText(tester, english.exportLastMonth);

      expect(find.text(english.exportNothing), findsOneWidget);
      expect(sharedPdfs, isEmpty);
    });
  });

  test('les périodes d\'export comptent aujourd\'hui', () {
    final today = DateTime(2026, 11, 19, 10);

    expect(ExportPeriod.lastWeek.firstDay(today), DateTime(2026, 11, 13));
    expect(ExportPeriod.lastMonth.firstDay(today), DateTime(2026, 10, 21));
    expect(ExportPeriod.allTime.firstDay(today), isNull);
  });
}
