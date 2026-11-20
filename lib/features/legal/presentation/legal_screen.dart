import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/async_view.dart';
import '../application/legal_providers.dart';
import '../domain/legal_document.dart';

String legalTitle(AppLocalizations l10n, LegalDocument document) =>
    switch (document) {
      LegalDocument.terms => l10n.legalTermsTitle,
      LegalDocument.privacy => l10n.legalPrivacyTitle,
    };

IconData legalIcon(LegalDocument document) => switch (document) {
  LegalDocument.terms => Icons.description_outlined,
  LegalDocument.privacy => Icons.shield_outlined,
};

/// Conditions d'utilisation ou politique de confidentialité, lisibles aussi
/// sans compte (depuis l'inscription).
class LegalScreen extends ConsumerWidget {
  const LegalScreen({required this.document, super.key});

  final LegalDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = (document, Localizations.localeOf(context).languageCode);

    return Scaffold(
      appBar: SoftAppBar(
        title: legalTitle(AppLocalizations.of(context), document),
      ),
      body: SafeArea(
        top: false,
        child: AsyncView(
          value: ref.watch(legalTextProvider(request)),
          onRetry: () => ref.invalidate(legalTextProvider(request)),
          builder: (blocks) {
            // Le titre du texte est déjà celui de la barre.
            final body = [
              for (final block in blocks)
                if (block.kind != LegalBlockKind.title) block,
            ];
            return SelectionArea(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xs,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                itemCount: body.length,
                itemBuilder: (context, index) => _LegalBlockView(body[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LegalBlockView extends StatelessWidget {
  const _LegalBlockView(this.block);

  final LegalBlock block;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return switch (block.kind) {
      LegalBlockKind.title || LegalBlockKind.section => Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.sm,
        ),
        child: Semantics(
          header: true,
          child: Text(block.text, style: textTheme.titleMedium),
        ),
      ),
      LegalBlockKind.listItem => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExcludeSemantics(child: Text('•  ')),
            Expanded(child: Text(block.text)),
          ],
        ),
      ),
      LegalBlockKind.paragraph => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text(block.text),
      ),
    };
  }
}

/// Liens vers les conditions d'utilisation et la politique de confidentialité.
class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (final document in LegalDocument.values)
          TextButton(
            onPressed: () => context.push(AppRoutes.legalOf(document)),
            child: Text(legalTitle(l10n, document)),
          ),
      ],
    );
  }
}
