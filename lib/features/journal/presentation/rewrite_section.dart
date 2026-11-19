import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/widgets/async_view.dart';
import '../../billing/application/billing_providers.dart';
import '../application/journal_providers.dart';
import '../domain/journal_entry.dart';
import '../domain/sentences.dart';

/// Phrases de la version corrigée, à reformuler en trois registres (US-13).
/// Sans abonnement, toucher une phrase présente les offres.
class RewriteSection extends ConsumerWidget {
  const RewriteSection({required this.entry, super.key});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isPremium = watchActiveSubscription(ref) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.rewriteTitle, style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.rewriteHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final sentence in splitSentences(entry.correctedText))
                ListTile(
                  title: Text(sentence),
                  trailing: isPremium
                      ? const Icon(Icons.chevron_right)
                      : Icon(
                          Icons.lock_outline,
                          semanticLabel: l10n.rewriteLocked,
                        ),
                  onTap: isPremium
                      ? () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (context) => _RewriteSheet(
                            request: (entryId: entry.id, sentence: sentence),
                          ),
                        )
                      : () => context.push(AppRoutes.paywall),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RewriteSheet extends ConsumerWidget {
  const _RewriteSheet({required this.request});

  final RewriteRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final provider = sentenceRewriteProvider(request);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(request.sentence, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            AsyncView(
              value: ref.watch(provider),
              onRetry: () => ref.invalidate(provider),
              builder: (rewrite) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (register, text) in [
                    (l10n.rewritePolite, rewrite.polite),
                    (l10n.rewriteCasual, rewrite.casual),
                    (l10n.rewriteProfessional, rewrite.professional),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            register,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SelectableText(text),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
