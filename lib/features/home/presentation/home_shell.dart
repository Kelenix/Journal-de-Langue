import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// Barre d'onglets flottante, aux coins arrondis ; chaque onglet conserve sa
/// propre pile.
class HomeShell extends StatelessWidget {
  const HomeShell({required this.navigationShell, super.key});

  static const _barHeight = 68.0;
  static const _barRadius = BorderRadius.all(Radius.circular(26));

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

    // Le contenu s'arrête au-dessus de la barre : rien ne reste caché dessous.
    return Scaffold(
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
            // La marge de sécurité est déjà appliquée autour de la barre.
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: NavigationBar(
                height: _barHeight,
                elevation: 0,
                backgroundColor: theme.cardColor,
                indicatorColor: theme.colorScheme.primaryContainer,
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _onDestinationSelected,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.edit_note_outlined),
                    label: l10n.tabJournal,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.history_outlined),
                    label: l10n.tabHistory,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.style_outlined),
                    label: l10n.tabReview,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.local_fire_department_outlined),
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
    );
  }
}
