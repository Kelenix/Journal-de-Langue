import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../presentation/failure_message.dart';

/// Affiche une donnée asynchrone : chargement, erreur avec « Réessayer », ou
/// contenu. Une erreur l'emporte sur la valeur précédente : après un changement
/// de langue raté, l'écran ne montre pas les données de l'ancienne langue.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    required this.value,
    required this.onRetry,
    required this.builder,
    super.key,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (value) {
      AsyncValue(:final error?, isLoading: false) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(failureMessage(l10n, error), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onRetry, child: Text(l10n.actionRetry)),
            ],
          ),
        ),
      ),
      // Une valeur `null` est une valeur (statistiques absentes, par exemple).
      AsyncValue(hasValue: true) => builder(value.requireValue),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
