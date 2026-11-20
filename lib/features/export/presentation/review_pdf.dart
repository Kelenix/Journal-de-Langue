import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../l10n/app_localizations.dart';
import '../../journal/domain/journal_entry.dart';
import '../../languages/domain/learning_language.dart';
import '../../languages/presentation/language_labels.dart';
import '../../vocabulary/domain/vocabulary_item.dart';

/// Polices de l'app (ADR-019), pour que les accents de toutes les langues
/// s'affichent. Données brutes : le PDF est construit dans un autre isolate.
typedef PdfFontData = ({ByteData body, ByteData heading});

/// Contenu du PDF, préparé sur l'isolate principal : les dates sont déjà
/// écrites, leurs données de langue n'existant que là.
typedef ReviewPdfContent = ({
  List<JournalEntry> entries,
  LearningLanguage language,
  String period,
  String generatedOn,
  Map<DateTime, String> entryDates,
});

/// Révisions dans un PDF : vocabulaire, puis chaque journal avec sa
/// correction. Le document est créé sur l'appareil (ADR-005).
Future<Uint8List> buildReviewPdf(
  ReviewPdfContent content,
  AppLocalizations l10n,
  PdfFontData fontData,
) {
  const ink = PdfColor.fromInt(0xFF20332E);
  const muted = PdfColor.fromInt(0xFF788680);
  final body = pw.Font.ttf(fontData.body);
  final headingFont = pw.Font.ttf(fontData.heading);
  final heading = pw.TextStyle(font: headingFont, fontSize: 15, color: ink);
  final entries = content.entries;
  final title = l10n.exportPdfTitle(languageName(l10n, content.language));

  final words = <String, VocabularyItem>{
    for (final entry in entries.reversed)
      for (final word in entry.vocabulary) word.term.toLowerCase(): word,
  }.values.toList();

  final document = pw.Document(title: title, creator: l10n.appTitle);
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      theme: pw.ThemeData.withFont(base: body, bold: headingFont),
      // Un historique Premium peut être long.
      maxPages: 200,
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: muted),
        ),
      ),
      build: (context) => [
        pw.Text(
          title,
          style: pw.TextStyle(font: headingFont, fontSize: 22, color: ink),
        ),
        pw.SizedBox(height: 4),
        pw.Text(content.period, style: const pw.TextStyle(color: muted)),
        pw.SizedBox(height: 20),
        pw.Text(l10n.correctionVocabularyTitle, style: heading),
        pw.SizedBox(height: 8),
        if (words.isEmpty)
          pw.Text(
            l10n.exportPdfNoWords,
            style: const pw.TextStyle(color: muted),
          )
        else
          pw.TableHelper.fromTextArray(
            headers: [
              l10n.exportPdfTerm,
              l10n.exportPdfTranslation,
              l10n.exportPdfExample,
            ],
            data: [
              for (final word in words)
                [word.term, word.translation, word.example],
            ],
            headerStyle: pw.TextStyle(font: headingFont, color: ink),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF7F4EA),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(3),
            },
          ),
        pw.SizedBox(height: 24),
        pw.Text(l10n.exportPdfCorrections, style: heading),
        for (final entry in entries) ...[
          pw.SizedBox(height: 14),
          pw.Text(
            content.entryDates[entry.entryDate] ?? '',
            style: pw.TextStyle(font: headingFont, color: ink),
          ),
          pw.SizedBox(height: 4),
          ..._labelled(l10n.correctionYourVersion, entry.originalText, muted),
          ..._labelled(
            l10n.correctionCorrectedVersion,
            entry.correctedText,
            muted,
          ),
          if (entry.items.isEmpty)
            pw.Text(l10n.correctionNoMistakes)
          else
            for (final item in entry.items)
              pw.Bullet(
                text: l10n.exportPdfMistake(
                  item.original,
                  item.corrected,
                  item.explanation,
                ),
              ),
        ],
        pw.SizedBox(height: 24),
        pw.Text(
          content.generatedOn,
          style: const pw.TextStyle(fontSize: 9, color: muted),
        ),
      ],
    ),
  );
  return document.save();
}

/// Un intitulé, puis un texte qui peut dépasser une page (journal Premium) :
/// enfants directs de la page, pour que le texte se coupe d'une page à l'autre.
List<pw.Widget> _labelled(String label, String text, PdfColor labelColor) => [
  pw.Text(label, style: pw.TextStyle(fontSize: 9, color: labelColor)),
  pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Text(text, overflow: pw.TextOverflow.span),
  ),
];
