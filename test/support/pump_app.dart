import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/app.dart';
import 'package:journal_de_langue/core/utils/clock.dart';
import 'package:journal_de_langue/features/auth/application/auth_providers.dart';
import 'package:journal_de_langue/features/journal/application/journal_providers.dart';
import 'package:journal_de_langue/features/languages/application/language_providers.dart';
import 'package:journal_de_langue/l10n/app_localizations.dart';

import 'fakes.dart';

/// Textes anglais : langue par défaut de l'environnement de test.
final english = lookupAppLocalizations(const Locale('en'));

/// « Maintenant » dans les tests.
final testNow = DateTime(2026, 11, 19, 10);

/// Écran d'un petit téléphone : 360 × 800 points.
const _phonePhysicalSize = Size(1080, 2400);
const _phonePixelRatio = 3.0;

/// Fait défiler jusqu'à [target] si nécessaire, puis appuie dessus.
Future<void> tapOn(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Lance l'application complète, sur un écran de téléphone et des données en
/// mémoire.
Future<void> pumpApp(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  required FakeLanguageRepository languages,
  FakeJournalRepository? journal,
  InMemoryJournalDraftStore? drafts,
}) async {
  tester.view
    ..physicalSize = _phonePhysicalSize
    ..devicePixelRatio = _phonePixelRatio;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        languageRepositoryProvider.overrideWithValue(languages),
        journalRepositoryProvider.overrideWithValue(
          journal ?? FakeJournalRepository(),
        ),
        journalDraftStoreProvider.overrideWithValue(
          drafts ?? InMemoryJournalDraftStore(),
        ),
        clockProvider.overrideWithValue(() => testNow),
      ],
      child: const JournalApp(),
    ),
  );
  await tester.pumpAndSettle();
}
