import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import 'day_change_observer.dart';

/// Barre d'onglets flottante, aux coins arrondis ; chaque onglet conserve sa
/// propre pile.
class HomeShell extends StatelessWidget {
  const HomeShell({required this.navigationShell, super.key});

  static const _barHeight = 72.0;
  static const _barRadius = BorderRadius.all(Radius.circular(26));
  static const _labelSize = 11.0;

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Retoucher l'onglet courant ramène à sa racine.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Le contenu s'arrête au-dessus de la barre : rien ne reste caché dessous.
    return DayChangeObserver(
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: _barRadius,
              boxShadow: theme.extension<AppColors>()!.softShadow,
            ),
            child: ClipRRect(
              borderRadius: _barRadius,
              // Les marges de l'écran (barre d'état comprise) sont déjà
              // appliquées autour de la barre : elle ne les ajoute pas dedans.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                removeBottom: true,
                removeLeft: true,
                removeRight: true,
                child: NavigationBar(
                  height: _barHeight,
                  elevation: 0,
                  backgroundColor: theme.cardColor,
                  indicatorColor: scheme.primaryContainer,
                  labelTextStyle: WidgetStateProperty.resolveWith(
                    (states) => theme.textTheme.labelSmall?.copyWith(
                      fontSize: _labelSize,
                      fontWeight: states.contains(WidgetState.selected)
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: states.contains(WidgetState.selected)
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.edit_outlined),
                      label: l10n.tabJournal,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.schedule_outlined),
                      label: l10n.tabHistory,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.copy_outlined),
                      label: l10n.tabReview,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.bar_chart_rounded),
                      label: l10n.tabProgress,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.person_outline),
                      label: l10n.tabProfile,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
