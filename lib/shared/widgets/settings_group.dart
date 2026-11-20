import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'badges.dart';
import 'surfaces.dart';

/// Lignes de réglages regroupées sur une carte blanche, séparées d'un filet.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      radius: AppRadius.tile,
      elevated: false,
      child: Column(
        children: [
          for (final (index, child) in children.indexed) ...[
            if (index > 0) const Divider(),
            child,
          ],
        ],
      ),
    );
  }
}

/// Ligne d'un [SettingsGroup] : pastille, libellé, valeur et chevron.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.warm = false,
    this.isDestructive = false,
    this.plain = false,
    super.key,
  });

  static const _badgeSize = 36.0;
  static const _valueMaxWidth = 150.0;

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Valeur courante, rappelée à droite (langue, offre…).
  final String? value;
  final VoidCallback? onTap;

  /// Pastille corail au lieu du vert.
  final bool warm;
  final bool isDestructive;

  /// Action simple (déconnexion…) : icône seule, sans pastille ni chevron.
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final error = theme.colorScheme.error;
    final subtitle = this.subtitle;
    final value = this.value;
    final hasChevron = onTap != null && !isDestructive && !plain;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      minVerticalPadding: AppSpacing.md,
      textColor: isDestructive ? error : null,
      leading: plain
          // Même largeur qu'une pastille : les libellés restent alignés.
          ? SizedBox(
              width: _badgeSize,
              child: Icon(icon, color: isDestructive ? error : muted),
            )
          : IconBadge(
              icon,
              size: _badgeSize,
              warm: warm,
              color: isDestructive ? error : null,
            ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: value == null && !hasChevron
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _valueMaxWidth),
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                  ),
                if (hasChevron)
                  ExcludeSemantics(
                    child: Icon(Icons.chevron_right, color: muted),
                  ),
              ],
            ),
      onTap: onTap,
    );
  }
}
