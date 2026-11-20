import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/features/export/presentation/review_pdf.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';
import 'package:journal_de_langue/l10n/app_localizations.dart';

import '../../support/fakes.dart';

/// Le PDF est construit dans un autre isolate (US-17) : tout ce qu'il reçoit
/// doit pouvoir y être envoyé, et rien ne doit y dépendre des données de dates.
void main() {
  ByteData font(String name) =>
      ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync());

  test('un long journal est mis en PDF dans un autre isolate', () async {
    final fonts = (
      body: font('Inter-Variable.ttf'),
      heading: font('DMSans-Variable.ttf'),
    );
    final l10n = lookupAppLocalizations(const Locale('fr'));
    // 6 000 caractères, la limite Premium : plus d'une page A4.
    final entry = sampleEntry(originalText: 'Today I has a cat. ' * 316);
    final content = (
      entries: [entry],
      language: LearningLanguage.english,
      period: 'Du 13 au 19 novembre 2026',
      generatedOn: 'Créé le 19 novembre 2026 avec Journal de Langue.',
      entryDates: {entry.entryDate: '19 novembre 2026'},
    );

    final bytes = await Isolate.run(() => buildReviewPdf(content, l10n, fonts));

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
