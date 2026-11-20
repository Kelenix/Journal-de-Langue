import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/failure.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/dates.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/application/action_controller.dart';
import '../../journal/application/journal_providers.dart';
import '../../languages/application/language_providers.dart';
import '../domain/export_period.dart';
import '../presentation/review_pdf.dart';

/// Ouvre la feuille de partage du système pour un fichier PDF ; remplacé dans
/// les tests.
typedef PdfSharer = Future<void> Function(Uint8List bytes, String fileName);

final pdfSharerProvider = Provider<PdfSharer>(
  (ref) =>
      (bytes, fileName) => SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
          fileNameOverrides: [fileName],
        ),
      ),
);

/// Polices de l'app, lues une fois.
final pdfFontsProvider = FutureProvider<PdfFontData>(
  (ref) async => (
    body: await rootBundle.load('assets/fonts/Inter-Variable.ttf'),
    heading: await rootBundle.load('assets/fonts/DMSans-Variable.ttf'),
  ),
);

typedef PdfBuilder =
    Future<Uint8List> Function(
      ReviewPdfContent content,
      AppLocalizations l10n,
      PdfFontData fonts,
    );

/// Construit le PDF dans un autre isolate : un long historique ne fige pas
/// l'écran. Remplacé dans les tests, où un isolate ne suit pas le temps simulé.
final pdfBuilderProvider = Provider<PdfBuilder>(
  (ref) =>
      (content, l10n, fonts) =>
          Isolate.run(() => buildReviewPdf(content, l10n, fonts)),
);

/// Export des révisions de la langue en cours (US-17).
class ExportController extends ActionController {
  Future<bool> export(ExportPeriod period, AppLocalizations l10n) => run(
    () async {
      final language = (await ref.read(activeLanguagesProvider.future)).first;
      final today = ref.read(clockProvider)();
      final firstDay = period.firstDay(today);
      final entries = await ref
          .read(journalRepositoryProvider)
          .entriesSince(language, firstDay: firstDay);
      if (entries.isEmpty) throw const NothingToExportFailure();

      final dates = DateFormat.yMMMMd(l10n.localeName);
      final content = (
        entries: entries,
        language: language,
        period: firstDay == null
            ? l10n.exportAll
            : l10n.exportPdfPeriod(dates.format(firstDay), dates.format(today)),
        generatedOn: l10n.exportPdfGenerated(dates.format(today)),
        entryDates: {
          for (final entry in entries)
            entry.entryDate: dates.format(entry.entryDate),
        },
      );
      final bytes = await ref.read(pdfBuilderProvider)(
        content,
        l10n,
        await ref.read(pdfFontsProvider.future),
      );
      await ref.read(pdfSharerProvider)(
        bytes,
        'journal-de-langue-${language.code}-${isoDate(today)}.pdf',
      );
    },
  );
}

final exportControllerProvider =
    NotifierProvider.autoDispose<ExportController, AsyncValue<void>>(
      ExportController.new,
    );
