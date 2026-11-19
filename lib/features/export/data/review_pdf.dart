import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../l10n/app_localizations.dart';
import '../../journal/domain/journal_entry.dart';
import '../../languages/domain/learning_language.dart';
import '../../languages/presentation/language_labels.dart';
import '../../vocabulary/domain/vocabulary_item.dart';

/// Polices embarquées dans le PDF : celles de l'app (ADR-019), pour que les
/// accents de toutes les langues s'affichent.
typedef PdfFonts = ({pw.Font body, pw.Font heading});

/// Révisions de [entries] dans un PDF : vocabulaire, puis chaque journal avec
/// sa correction. Le document est créé sur l'appareil (ADR-005).
Future<Uint8List> buildReviewPdf({
  required List<JournalEntry> entries,
  required LearningLanguage language,
  required DateTime? firstDay,
  required DateTime today,
  required AppLocalizations l10n,
  required PdfFonts fonts,
}) {
  final dates = DateFormat.yMMMMd(l10n.localeName);
  const ink = PdfColor.fromInt(0xFF20332E);
  const muted = PdfColor.fromInt(0xFF788680);
  final heading = pw.TextStyle(font: fonts.heading, fontSize: 15, color: ink);

  final words = <String, VocabularyItem>{
    for (final entry in entries.reversed)
      for (final word in entry.vocabulary) word.term.toLowerCase(): word,
  }.values.toList();

  final document = pw.Document(
    title: l10n.exportPdfTitle(languageName(l10n, language)),
    creator: l10n.appTitle,
  );
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      theme: pw.ThemeData.withFont(base: fonts.body, bold: fonts.heading),
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
          l10n.exportPdfTitle(languageName(l10n, language)),
          style: pw.TextStyle(font: fonts.heading, fontSize: 22, color: ink),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          firstDay == null
              ? l10n.exportAll
              : l10n.exportPdfPeriod(
                  dates.format(firstDay),
                  dates.format(today),
                ),
          style: const pw.TextStyle(color: muted),
        ),
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
            headerStyle: pw.TextStyle(font: fonts.heading, color: ink),
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
            dates.format(entry.entryDate),
            style: pw.TextStyle(font: fonts.heading, color: ink),
          ),
          pw.SizedBox(height: 4),
          _labelled(l10n.correctionYourVersion, entry.originalText, muted),
          _labelled(
            l10n.correctionCorrectedVersion,
            entry.correctedText,
            muted,
          ),
          if (entry.items.isEmpty)
            pw.Text(l10n.correctionNoMistakes)
          else
            for (final item in entry.items)
              pw.Bullet(
                text:
                    '${item.original} → ${item.corrected} : '
                    '${item.explanation}',
              ),
        ],
        pw.SizedBox(height: 24),
        pw.Text(
          l10n.exportPdfGenerated(dates.format(today)),
          style: const pw.TextStyle(fontSize: 9, color: muted),
        ),
      ],
    ),
  );
  return document.save();
}

pw.Widget _labelled(String label, String text, PdfColor labelColor) =>
    pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, color: labelColor)),
          pw.Text(text),
        ],
      ),
    );
