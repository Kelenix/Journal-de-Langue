import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/brand_header.dart';
import '../../../shared/widgets/surfaces.dart';

/// Première page sans compte : la marque sur l'aplat vert, ce que l'app
/// apporte, puis l'inscription ou la connexion.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _sheetRadius = Radius.circular(32);
  static const _maxContentWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemBarsOnHero,
      child: Scaffold(
        backgroundColor: theme.extension<AppColors>()!.hero,
        // Défile seulement si l'écran est trop petit (ou le texte très grand).
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(
                      child: HeroCard(
                        borderRadius: BorderRadius.zero,
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.xl,
                          AppSpacing.xl,
                          AppSpacing.xxl,
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Center(child: BrandHeader()),
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
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: _maxContentWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    l10n.welcomeTitle,
                                    style: theme.textTheme.headlineSmall,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _Feature(
                                  icon: Icons.edit_outlined,
                                  label: l10n.welcomeFeatureWrite,
                                ),
                                _Feature(
                                  icon: Icons.check,
                                  label: l10n.welcomeFeatureCorrect,
                                  warm: true,
                                ),
                                _Feature(
                                  icon: Icons.style_outlined,
                                  label: l10n.welcomeFeatureReview,
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                FilledButton(
                                  onPressed: () =>
                                      context.push(AppRoutes.signUp),
                                  child: Text(l10n.authSignUpAction),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextButton(
                                  onPressed: () =>
                                      context.push(AppRoutes.signIn),
                                  child: Text(l10n.welcomeHaveAccount),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

/// Ce que l'app apporte, en une ligne.
class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label, this.warm = false});

  final IconData icon;
  final String label;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          IconBadge(icon, warm: warm),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
