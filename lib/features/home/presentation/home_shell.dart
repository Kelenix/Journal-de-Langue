import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

/// Barre d'onglets principale ; chaque onglet conserve sa propre pile.
class HomeShell extends StatelessWidget {
  const HomeShell({required this.navigationShell, super.key});

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
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
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
    );
  }
}
