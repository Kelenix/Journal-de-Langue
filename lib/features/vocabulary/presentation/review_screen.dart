import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabReview)),
      body: SafeArea(
        child: EmptyState(
          icon: Icons.style_outlined,
          message: l10n.reviewEmpty,
        ),
      ),
    );
  }
}
