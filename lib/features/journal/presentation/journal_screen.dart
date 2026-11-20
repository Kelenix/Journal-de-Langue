import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/clock.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../ads/domain/ad_status.dart';
import '../../ads/presentation/ad_widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../languages/application/language_providers.dart';
import '../../languages/domain/learning_language.dart';
import '../../languages/presentation/language_labels.dart';
import '../../stats/application/stats_providers.dart';
import '../application/journal_providers.dart';
import '../domain/journal_entry.dart';
import 'journal_editor.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final userId = ref.watch(currentUserIdProvider).value;
    final languages = ref.watch(activeLanguagesProvider).value ?? const [];
    final language = languages.firstOrNull;
    final today = DateFormat.MMMMEEEEd(
      l10n.localeName,
    ).format(ref.watch(clockProvider)());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.hero,
        foregroundColor: colors.onHero,
        centerTitle: false,
        titleSpacing: AppSpacing.xl,
        title: Text(
          toBeginningOfSentenceCase(today, l10n.localeName),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onHeroMuted,
          ),
        ),
        actions: [
          if (language != null) _LanguagePill(languages: languages),
          const SizedBox(width: AppSpacing.lg),
        ],
      ),
      // Sans session ni langue, la navigation quitte cet écran.
      body: userId == null || language == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              children: [
                const _Greeting(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg,
                    0,
                  ),
                  child: AsyncView(
                    value: ref.watch(journalDayProvider),
                    onRetry: () async {
                      await reloadFailedSubscription(ref);
                      ref.invalidate(journalDayProvider);
                    },
                    builder: (day) => day.allowance.canCorrect
                        ? JournalEditor(
                            // Un brouillon par compte et par langue.
                            key: ValueKey((userId, language)),
                            userId: userId,
                            language: language,
                            allowance: day.allowance,
                          )
                        : _DailyLimitReached(
                            entryId: day.entryId,
                            isPremium: day.allowance.plan != null,
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Langue du journal ; à choisir parmi celles de l'abonné s'il en a plusieurs.
class _LanguagePill extends ConsumerWidget {
  const _LanguagePill({required this.languages});

  static const _height = 36.0;
  static const _borderOpacity = 0.35;

  final List<LearningLanguage> languages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final onHero = theme.extension<AppColors>()!.onHero;
    final canSwitch = languages.length > 1;

    final pill = Center(
      child: Container(
        height: _height,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_height / 2),
          border: Border.all(color: onHero.withValues(alpha: _borderOpacity)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              languageName(l10n, languages.first),
              style: theme.textTheme.labelLarge?.copyWith(color: onHero),
            ),
            if (canSwitch) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.expand_more, size: 18, color: onHero),
            ],
          ],
        ),
      ),
    );
    if (!canSwitch) return pill;

    ref.listen(journalLanguageControllerProvider, (_, next) {
      final error = next.error;
      if (error == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage(l10n, error))));
    });

    return PopupMenuButton<LearningLanguage>(
      tooltip: l10n.journalSwitchLanguage,
      enabled: !ref.watch(journalLanguageControllerProvider).isLoading,
      onSelected: (language) =>
          ref.read(journalLanguageControllerProvider.notifier).select(language),
      itemBuilder: (context) => [
        for (final language in languages.skip(1))
          PopupMenuItem(
            value: language,
            child: Text(languageName(l10n, language)),
          ),
      ],
      child: pill,
    );
  }
}

/// Accueil sur l'aplat vert : salutation et semaine d'écriture.
class _Greeting extends StatelessWidget {
  const _Greeting();

  static const _radius = Radius.circular(32);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return HeroCard(
      borderRadius: const BorderRadius.vertical(bottom: _radius),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      // Les styles sont lus sous la carte, aux couleurs de l'aplat.
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.journalGreeting,
                  style: theme.textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.journalHeadline,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const _WeekStreak(),
            ],
          );
        },
      ),
    );
  }
}

/// Série en cours et jours écrits de la semaine. Rien pendant le chargement.
class _WeekStreak extends ConsumerWidget {
  const _WeekStreak();

  static const _panelOpacity = 0.1;
  static const _badgeSize = 44.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider).value;
    if (stats == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final written = {for (final day in stats.weekDays) DateUtils.dateOnly(day)};

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.onHero.withValues(alpha: _panelOpacity),
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: _badgeSize,
                  height: _badgeSize,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    color: colors.onAccent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.streakDays > 0
                          ? l10n.journalStreak(stats.streakDays)
                          : l10n.progressStreakStart,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Semantics(
                      label: l10n.journalWeekSummary(written.length),
                      child: ExcludeSemantics(
                        child: _WeekDots(
                          today: DateUtils.dateOnly(ref.watch(clockProvider)()),
                          written: written,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Du lundi au dimanche : jours écrits pleins, aujourd'hui cerclé.
class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.today, required this.written});

  static const _maxDotSize = 26.0;
  static const _gap = 6.0;
  static const _ringWidth = 2.0;
  static const _dimOpacity = 0.14;

  final DateTime today;
  final Set<DateTime> written;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    // Initiale du jour, dans la langue de l'interface.
    final initial = DateFormat(
      'ccccc',
      AppLocalizations.of(context).localeName,
    );
    final days = [
      for (var offset = 0; offset < DateTime.daysPerWeek; offset++)
        DateTime(
          today.year,
          today.month,
          today.day - today.weekday + 1 + offset,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(
          _maxDotSize,
          (constraints.maxWidth - _gap * (days.length - 1)) / days.length,
        );
        return MediaQuery.withNoTextScaling(
          child: Row(
            spacing: _gap,
            children: [
              for (final day in days)
                Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: written.contains(day)
                        ? colors.accent
                        : day == today
                        ? null
                        : colors.onHero.withValues(alpha: _dimOpacity),
                    border: day == today && !written.contains(day)
                        ? Border.all(color: colors.accent, width: _ringWidth)
                        : null,
                  ),
                  child: Text(
                    initial.format(day),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: written.contains(day)
                          ? colors.onAccent
                          : day == today
                          ? colors.onHero
                          : colors.onHeroMuted,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// La correction du jour est utilisée : accès à la correction et rappel.
class _DailyLimitReached extends ConsumerWidget {
  const _DailyLimitReached({required this.entryId, required this.isPremium});

  static const _badgeRadius = 28.0;

  final String? entryId;
  final bool isPremium;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final muted = theme.colorScheme.onSurfaceVariant;
    final entryId = this.entryId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (entryId != null) ...[
          SoftCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExcludeSemantics(
                  child: CircleAvatar(
                    radius: _badgeRadius,
                    backgroundColor: colors.accent,
                    foregroundColor: colors.onAccent,
                    child: const Icon(Icons.check),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.journalCorrectedTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.journalCorrectedBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () =>
                      context.push(AppRoutes.correctionOf(entryId)),
                  child: Text(l10n.journalViewCorrection),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (isPremium)
          Text(
            l10n.journalPremiumLimitReached,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          )
        else
          // Sur le journal, l'offre payante n'apparaît qu'une fois la
          // correction gratuite du jour utilisée (INTAKE §6).
          SoftCard(
            color: theme.colorScheme.secondaryContainer,
            elevated: false,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.journalDailyLimitReached,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => context.push(AppRoutes.paywall),
                  child: Text(l10n.paywallDiscover),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Sans abonnement : des corrections à l'unité (US-18).
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.shop),
                  child: Text(l10n.journalBuyCorrections),
                ),
                // Ou une vidéo : une correction de plus par jour (US-23).
                RewardedAdButton(
                  kind: AdRewardKind.correction,
                  onReload: () => ref.invalidate(journalDayProvider),
                ),
              ],
            ),
          ),
        const AdBanner(),
      ],
    );
  }
}
