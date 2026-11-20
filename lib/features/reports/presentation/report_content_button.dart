import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/presentation/failure_message.dart';
import '../application/report_providers.dart';
import '../domain/content_report_repository.dart';

/// Signale un contenu produit par l'IA, sans quitter l'app (règle Google Play
/// sur les contenus générés par IA, ADR-034).
class ReportContentButton extends ConsumerWidget {
  const ReportContentButton({
    required this.content,
    required this.targetId,
    this.style,
    super.key,
  });

  final ReportedContent content;
  final String targetId;
  final ButtonStyle? style;

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final comment = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _ReportDialog(),
    );
    if (comment == null) return;

    try {
      await ref
          .read(contentReportRepositoryProvider)
          .report(content, targetId, comment: comment.isEmpty ? null : comment);
      messenger.showSnackBar(SnackBar(content: Text(l10n.reportThanks)));
    } on Failure catch (failure) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, failure))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: AppLocalizations.of(context).reportAction,
    style: style,
    icon: const Icon(Icons.flag_outlined),
    onPressed: () => _report(context, ref),
  );
}

/// Rend le commentaire saisi (éventuellement vide), ou `null` si annulé.
class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  static const _maxLength = 500;

  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.reportTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.reportBody),
            TextField(
              controller: _comment,
              maxLength: _maxLength,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.reportHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_comment.text.trim()),
          child: Text(l10n.reportSend),
        ),
      ],
    );
  }
}
