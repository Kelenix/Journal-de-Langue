import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProgress)),
      body: SafeArea(
        child: EmptyState(
          icon: Icons.local_fire_department_outlined,
          message: l10n.progressEmpty,
        ),
      ),
    );
  }
}
