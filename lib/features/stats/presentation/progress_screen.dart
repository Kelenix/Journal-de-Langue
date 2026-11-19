import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/clock.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../journal/application/journal_providers.dart';
import '../../journal/presentation/category_labels.dart';
import '../../languages/application/language_providers.dart';
import '../../languages/domain/learning_language.dart';
import '../../languages/presentation/language_labels.dart';
import '../application/stats_providers.dart';
import '../domain/learning_stats.dart';

/// Série de jours, puis, en Premium, mots appris, fautes par type et fautes
/// par phrase semaine après semaine (US-16).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(activeLanguagesProvider).value?.firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProgress)),
      body: SafeArea(
        child: AsyncView(
          value: ref.watch(statsProvider),
          onRetry: () => ref.invalidate(statsProvider),
          builder: (stats) => stats == null || language == null
              ? const SizedBox.shrink()
              : stats.streakDays == 0 && stats.journals == 0
              ? EmptyState(
                  icon: Icons.local_fire_department_outlined,
                  message: l10n.progressEmpty,
                )
              : _Progress(
                  stats: stats,
                  language: language,
                  today: ref.watch(clockProvider)(),
                ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.stats,
    required this.language,
    required this.today,
  });

  final LearningStats stats;
  final LearningLanguage language;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wordsLearned = stats.wordsLearned;
    final wordsTotal = stats.wordsTotal;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _StreakCard(days: stats.streakDays),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StatTile(
                label: l10n.progressJournals(languageName(l10n, language)),
                value: '${stats.journals}',
              ),
            ),
            if (wordsLearned != null && wordsTotal != null) ...[
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatTile(
                  label: l10n.progressWordsLearned,
                  value: '$wordsLearned',
                  detail: l10n.progressWordsOf(wordsTotal),
                  meter: wordsTotal == 0 ? 0 : wordsLearned / wordsTotal,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (stats.isPremium) ...[
          _MistakesByCategory(counts: stats.mistakesByCategory),
          const SizedBox(height: AppSpacing.md),
          _WeeklyMistakeRate(weeks: stats.weeklyMistakeRate, today: today),
        ] else
          const _PremiumTeaser(),
      ],
    );
  }
}

/// La série : le chiffre de l'écran.
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.days});

  static const _heroSize = 56.0;

  final int days;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.progressStreakLabel, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$days',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: _heroSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.progressStreakUnit(days),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                days == 0 ? l10n.progressStreakStart : l10n.progressStreakKeep,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.detail,
    this.meter,
  });

  final String label;
  final String value;
  final String? detail;

  /// Part remplie, de 0 à 1.
  final double? meter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meter = this.meter;
    final detail = this.detail;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(value, style: theme.textTheme.headlineSmall),
              if (detail != null)
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (meter != null) ...[
                const SizedBox(height: AppSpacing.sm),
                ExcludeSemantics(child: _Meter(value: meter)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Jauge : le remplissage et sa piste sont deux teintes de la même couleur.
class _Meter extends StatelessWidget {
  const _Meter({required this.value});

  static const _height = 8.0;

  final double value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(_height / 2),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: _height,
        color: scheme.primary,
        backgroundColor: scheme.primaryContainer,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

/// Barres horizontales classées, une couleur, le nombre au bout de chaque
/// barre.
class _MistakesByCategory extends StatelessWidget {
  const _MistakesByCategory({required this.counts});

  static const _barThickness = 10.0;
  static const _dataEndRadius = Radius.circular(4);

  final List<CategoryCount> counts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final highest = counts.fold(0, (most, entry) => max(most, entry.count));

    return _Section(
      title: l10n.progressMistakesTitle,
      child: counts.isEmpty
          ? Text(l10n.progressMistakesEmpty)
          : Column(
              children: [
                for (final entry in counts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: MergeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(errorCategoryName(l10n, entry.category)),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Expanded(
                                child: FractionallySizedBox(
                                  alignment: AlignmentDirectional.centerStart,
                                  widthFactor: entry.count / highest,
                                  child: Container(
                                    height: _barThickness,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      // Arrondi au bout, carré à la base.
                                      borderRadius:
                                          const BorderRadiusDirectional.horizontal(
                                            end: _dataEndRadius,
                                          ).resolve(Directionality.of(context)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '${entry.count}',
                                style: theme.textTheme.labelLarge,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Colonnes des 8 dernières semaines, une par semaine, vides comprises : l'axe
/// du temps reste régulier. Seule la dernière valeur est écrite ; chaque
/// colonne la donne au toucher, et le détail reste lisible en liste.
class _WeeklyMistakeRate extends StatelessWidget {
  const _WeeklyMistakeRate({required this.weeks, required this.today});

  static const _weekCount = 8;
  static const _plotHeight = 120.0;
  static const _labelSpace = 24.0;

  final List<WeeklyMistakeRate> weeks;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dayMonth = DateFormat.MMMd(locale);
    final rate = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    );
    final highest = weeks.fold(
      0.0,
      (most, week) => max(most, week.mistakesPerSentence),
    );

    // Lundis des 8 dernières semaines, comme les semaines du serveur.
    final thisMonday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - DateTime.monday),
    );
    final mondays = [
      for (var back = _weekCount - 1; back >= 0; back--)
        DateTime(thisMonday.year, thisMonday.month, thisMonday.day - 7 * back),
    ];
    final byMonday = {
      for (final week in weeks) DateUtils.dateOnly(week.weekStart): week,
    };
    final latest = weeks.lastOrNull;

    String describe(WeeklyMistakeRate week) => l10n.progressRateWeek(
      dayMonth.format(week.weekStart),
      rate.format(week.mistakesPerSentence),
    );

    return _Section(
      title: l10n.progressRateTitle,
      subtitle: l10n.progressRateSubtitle,
      child: weeks.isEmpty
          ? Text(l10n.progressRateEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: _plotHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final monday in mondays)
                        Expanded(
                          child: switch (byMonday[monday]) {
                            null => const SizedBox.shrink(),
                            final week => Tooltip(
                              message: describe(week),
                              triggerMode: TooltipTriggerMode.tap,
                              child: Semantics(
                                label: describe(week),
                                excludeSemantics: true,
                                child: _Column(
                                  // Même échelle pour toutes les colonnes ;
                                  // une semaine sans faute garde un trait.
                                  height: max(
                                    2,
                                    (_plotHeight - _labelSpace) *
                                        (highest == 0
                                            ? 0
                                            : week.mistakesPerSentence /
                                                  highest),
                                  ),
                                  label: week == latest
                                      ? rate.format(week.mistakesPerSentence)
                                      : null,
                                ),
                              ),
                            ),
                          },
                        ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                const SizedBox(height: AppSpacing.xs),
                ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final monday in [mondays.first, mondays.last])
                        Text(
                          dayMonth.format(monday),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    l10n.progressRateDetails,
                    style: theme.textTheme.bodyMedium,
                  ),
                  children: [
                    for (final week in weeks.reversed)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(describe(week)),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

/// Une colonne posée sur la ligne de base, sa valeur écrite juste au-dessus.
class _Column extends StatelessWidget {
  const _Column({required this.height, this.label});

  static const _width = 20.0;
  static const _labelGap = 2.0;
  static const _dataEndRadius = Radius.circular(4);

  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = this.label;

    // L'étiquette se place dans la marge réservée en haut du graphique, sans
    // agrandir la colonne.
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: _width,
          height: height,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: const BorderRadius.vertical(top: _dataEndRadius),
          ),
        ),
        if (label != null)
          Positioned(
            bottom: height + _labelGap,
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
      ],
    );
  }
}

/// Gratuit : ce que Premium ajoute. L'offre n'est proposée qu'après une
/// première correction (INTAKE §6).
class _PremiumTeaser extends ConsumerWidget {
  const _PremiumTeaser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return _Section(
      title: l10n.progressPremiumTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(l10n.progressPremiumBody)),
            ],
          ),
          if (watchHasCorrectedJournal(ref)) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.paywall),
              child: Text(l10n.paywallDiscover),
            ),
          ],
        ],
      ),
    );
  }
}
