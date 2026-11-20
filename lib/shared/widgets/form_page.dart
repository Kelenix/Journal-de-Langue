import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'surfaces.dart';

/// Mise en page des écrans de compte : titre sur l'aplat vert, contenu
/// défilant (le clavier ne masque rien), largeur bornée sur grand écran.
class FormPage extends StatelessWidget {
  const FormPage({required this.title, required this.children, super.key});

  static const _maxContentWidth = 480.0;
  static const _headerRadius = Radius.circular(32);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.hero,
        foregroundColor: colors.onHero,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeroCard(
              borderRadius: const BorderRadius.vertical(bottom: _headerRadius),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              child: _Bounded(
                child: Builder(
                  builder: (context) => Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: _Bounded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
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
