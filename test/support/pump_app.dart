import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/app.dart';
import 'package:journal_de_langue/core/utils/clock.dart';
import 'package:journal_de_langue/core/utils/external_links.dart';
import 'package:journal_de_langue/features/auth/application/auth_providers.dart';
import 'package:journal_de_langue/features/billing/application/billing_providers.dart';
import 'package:journal_de_langue/features/journal/application/journal_providers.dart';
import 'package:journal_de_langue/features/languages/application/language_providers.dart';
import 'package:journal_de_langue/features/vocabulary/application/vocabulary_providers.dart';
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
  FakeVocabularyRepository? vocabulary,
  InMemoryJournalDraftStore? drafts,
  FakeSubscriptionRepository? subscriptions,
  FakeBillingRepository? billing,
  List<Uri>? openedUrls,
}) async {
  tester.view
    ..physicalSize = _phonePhysicalSize
    ..devicePixelRatio = _phonePixelRatio;
  addTearDown(tester.view.reset);

  final vocabularyRepository = vocabulary ?? FakeVocabularyRepository();
  final subscriptionRepository = subscriptions ?? FakeSubscriptionRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        languageRepositoryProvider.overrideWithValue(languages),
        journalRepositoryProvider.overrideWithValue(
          journal ??
              FakeJournalRepository(
                vocabulary: vocabularyRepository,
                subscriptions: subscriptionRepository,
              ),
        ),
        subscriptionRepositoryProvider.overrideWithValue(
          subscriptionRepository,
        ),
        billingRepositoryProvider.overrideWithValue(
          billing ?? FakeBillingRepository(subscriptionRepository),
        ),
        urlOpenerProvider.overrideWithValue((uri) async {
          openedUrls?.add(uri);
          return true;
        }),
        vocabularyRepositoryProvider.overrideWithValue(vocabularyRepository),
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
