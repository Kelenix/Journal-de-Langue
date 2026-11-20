import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'badges.dart';

/// État « vide » commun aux écrans.
class EmptyState extends StatelessWidget {
  const EmptyState({required this.icon, required this.message, super.key});

  static const _badgeSize = 72.0;

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBadge(icon, size: _badgeSize),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
