import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Bouton rond posé sur le fond : retour, signalement, export…
ButtonStyle roundButtonStyle(BuildContext context) {
  final theme = Theme.of(context);
  return IconButton.styleFrom(
    backgroundColor: theme.cardColor,
    foregroundColor: theme.colorScheme.onSurface,
    elevation: 2,
    shadowColor: theme.extension<AppColors>()!.hero,
  );
}

/// Barre des écrans ouverts par-dessus les onglets : titre centré, retour
/// (ou fermeture) et actions en boutons ronds.
class SoftAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SoftAppBar({this.title, this.actions = const [], super.key});

  static const _height = 64.0;
  static const _leadingWidth = 68.0;

  final String? title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final style = roundButtonStyle(context);
    final title = this.title;

    return AppBar(
      toolbarHeight: _height,
      leadingWidth: _leadingWidth,
      automaticallyImplyLeading: false,
      leading: (route?.impliesAppBarDismissal ?? false)
          ? Center(
              child: route is PageRoute && route.fullscreenDialog
                  ? CloseButton(style: style)
                  : BackButton(style: style),
            )
          : null,
      title: title == null ? null : Text(title),
      actions: [
        ...actions,
        const SizedBox(width: AppSpacing.md),
      ],
    );
  }
}

/// Barre des onglets : grand titre à gauche, actions à droite.
class TabAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TabAppBar({
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    super.key,
  });

  static const _height = 80.0;

  /// Les grands titres sont déjà lisibles : leur agrandissement est borné
  /// pour qu'ils tiennent dans la barre.
  static const _maxTitleScale = 1.4;

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;
    final leading = this.leading;

    return AppBar(
      toolbarHeight: _height,
      centerTitle: false,
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.xl,
      title: MediaQuery.withClampedTextScaling(
        maxScaleFactor: _maxTitleScale,
        child: Row(
          children: [
            if (leading != null) ...[
              leading,
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: subtitle == null
                        ? theme.textTheme.headlineMedium
                        : theme.textTheme.titleLarge,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ...actions,
        const SizedBox(width: AppSpacing.lg),
      ],
    );
  }
}

/// Marges du contenu d'un onglet.
const tabPagePadding = EdgeInsets.fromLTRB(
  AppSpacing.lg,
  AppSpacing.xs,
  AppSpacing.lg,
  AppSpacing.lg,
);
