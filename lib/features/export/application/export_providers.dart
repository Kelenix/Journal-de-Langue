import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/failure.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/dates.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/application/action_controller.dart';
import '../../journal/application/journal_providers.dart';
import '../../languages/application/language_providers.dart';
import '../data/review_pdf.dart';
import '../domain/export_period.dart';

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

/// Polices de l'app, chargées une fois.
final pdfFontsProvider = FutureProvider<PdfFonts>((ref) async {
  final body = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
  final heading = await rootBundle.load('assets/fonts/DMSans-Variable.ttf');
  return (body: pw.Font.ttf(body), heading: pw.Font.ttf(heading));
});

/// Export des révisions de la langue en cours (US-17).
class ExportController extends ActionController {
  Future<bool> export(ExportPeriod period, AppLocalizations l10n) =>
      run(() async {
        final language = (await ref.read(activeLanguagesProvider.future)).first;
        final today = ref.read(clockProvider)();
        final firstDay = period.firstDay(today);
        final entries = [
          for (final entry
              in await ref.read(journalRepositoryProvider).recentEntries())
            if (entry.language == language &&
                (firstDay == null || !entry.entryDate.isBefore(firstDay)))
              entry,
        ];
        if (entries.isEmpty) throw const NothingToExportFailure();

        final bytes = await buildReviewPdf(
          entries: entries,
          language: language,
          firstDay: firstDay,
          today: today,
          l10n: l10n,
          fonts: await ref.read(pdfFontsProvider.future),
        );
        await ref.read(pdfSharerProvider)(
          bytes,
          'journal-de-langue-${language.code}-${isoDate(today)}.pdf',
        );
      });
}

final exportControllerProvider =
    NotifierProvider.autoDispose<ExportController, AsyncValue<void>>(
      ExportController.new,
    );
