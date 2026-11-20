import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'brand_header.dart';
import 'surfaces.dart';

/// Mise en page des écrans de compte, comme l'accueil : logo et titre au milieu
/// de l'aplat vert, contenu sur une feuille ivoire calée en bas de l'écran
/// (ADR-042). Tout défile si la place manque (clavier ouvert, grands
/// caractères) ; largeur bornée sur grand écran.
class FormPage extends StatelessWidget {
  const FormPage({required this.title, required this.children, super.key});

  static const _maxContentWidth = 480.0;
  static const _sheetRadius = Radius.circular(32);
  static const _logoSize = 72.0;

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.hero,
      appBar: AppBar(
        backgroundColor: colors.hero,
        foregroundColor: colors.onHero,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              // La place libre se partage de part et d'autre du titre : il reste
              // au milieu de l'aplat et la feuille touche le bas de l'écran.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox.shrink(),
                HeroCard(
                  borderRadius: BorderRadius.zero,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                  ),
                  child: _Bounded(
                    child: Column(
                      children: [
                        const BrandLogo(size: _logoSize),
                        const SizedBox(height: AppSpacing.lg),
                        Builder(
                          builder: (context) => Semantics(
                            header: true,
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: _sheetRadius,
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xxl,
                      AppSpacing.xl,
                      AppSpacing.xl,
                    ),
                    child: _Bounded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Centre son contenu sur une largeur de lecture confortable.
class _Bounded extends StatelessWidget {
  const _Bounded({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: FormPage._maxContentWidth),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}
