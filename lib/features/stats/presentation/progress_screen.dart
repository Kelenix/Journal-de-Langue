import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/clock.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../journal/application/journal_providers.dart';
import '../../journal/presentation/category_labels.dart';
import '../../languages/application/language_providers.dart';
import '../../languages/domain/learning_language.dart';
import '../../languages/presentation/language_labels.dart';
import '../application/stats_providers.dart';
import '../domain/learning_stats.dart';

/// Série de jours et journaux écrits, puis, en Premium, journaux par
/// semaine, mots appris et fautes fréquentes (US-16).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(activeLanguagesProvider).value?.firstOrNull;
    return Scaffold(
      appBar: TabAppBar(
        title: l10n.tabProgress,
        actions: [if (language != null) _LanguageChip(language: language)],
      ),
      body: AsyncView(
        value: ref.watch(statsProvider),
        onRetry: () => ref.invalidate(statsProvider),
        builder: (stats) => stats == null || language == null
            ? const SizedBox.shrink()
            : stats.streakDays == 0 && stats.journals == 0
            ? EmptyState(
                icon: Icons.local_fire_department_outlined,
                message: l10n.progressEmpty,
              )
            : _Progress(stats: stats, today: ref.watch(clockProvider)()),
      ),
    );
  }
}

/// Langue dont les progrès sont affichés.
class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.language});

  static const _height = 36.0;

  final LearningLanguage language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        height: _height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(_height / 2),
        ),
        child: Text(
          languageName(AppLocalizations.of(context), language),
          style: theme.textTheme.labelLarge,
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.stats, required this.today});

  final LearningStats stats;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wordsLearned = stats.wordsLearned;

    return ListView(
      padding: tabPagePadding,
      children: [
        _StreakCard(days: stats.streakDays),
        const SizedBox(height: AppSpacing.md),
        if (stats.isPremium) ...[
          _WeeklyJournalsChart(weeks: stats.weeklyJournals, today: today),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StatTile(
                label: l10n.progressJournals,
                value: '${stats.journals}',
              ),
            ),
            if (wordsLearned != null) ...[
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatTile(
                  label: l10n.progressWordsLearned,
                  value: '$wordsLearned',
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (stats.isPremium)
          _MistakesByCategory(counts: stats.mistakesByCategory)
        else
          const _PremiumTeaser(),
      ],
    );
  }
}

/// La série : le chiffre de l'écran, sur l'aplat vert.
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.days});

  static const _heroSize = 56.0;
  static const _unitSize = 15.0;
  static const _flameSize = 84.0;
  static const _flameIconSize = 40.0;

  final int days;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return HeroCard(
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sheet)),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final colors = theme.extension<AppColors>()!;
          final muted = theme.colorScheme.onSurfaceVariant;
          return Row(
            children: [
              Expanded(
                child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.progressStreakLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '$days',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontSize: _heroSize,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        l10n.progressStreakUnit(days),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: _unitSize,
                        ),
                      ),
                      if (days == 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.progressStreakStart,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              ExcludeSemantics(
                child: Container(
                  width: _flameSize,
                  height: _flameSize,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_fire_department_outlined,
                    size: _flameIconSize,
                    color: colors.onAccent,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  static const _valueSize = 28.0;
  static const _labelSize = 13.0;

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftCard(
      radius: AppRadius.tile,
      elevated: false,
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: _valueSize,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: _labelSize,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte blanche à titre, sans ombre ; une précision peut suivre le titre.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  static const _trailingSize = 13.0;

  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailing = this.trailing;
    return SoftCard(
      elevated: false,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  trailing,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: _trailingSize,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

/// Une colonne par semaine sur les 8 dernières, vides comprises : l'axe du
/// temps reste régulier. La semaine en cours ressort en vert profond.
class _WeeklyJournalsChart extends StatelessWidget {
  const _WeeklyJournalsChart({required this.weeks, required this.today});

  static const _weekCount = 8;
  static const _plotHeight = 104.0;
  static const _gap = 8.0;
  static const _labelGap = 6.0;
  static const _emptyBar = 2.0;
  static const _pastOpacity = 0.23;
  static const _barRadius = BorderRadius.vertical(
    top: Radius.circular(8),
    bottom: Radius.circular(4),
  );

  final List<WeeklyJournals> weeks;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Jour et mois : « 29/9 » en français, « 9/29 » en anglais.
    final dayMonth = l10n.localeName == 'fr'
        ? DateFormat('d/M', 'fr')
        : DateFormat.Md(l10n.localeName);

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
      for (final week in weeks)
        DateUtils.dateOnly(week.weekStart): week.journals,
    };
    final counts = [for (final monday in mondays) byMonday[monday] ?? 0];
    final highest = counts.fold(0, max);

    return _Section(
      title: l10n.progressWeeklyTitle,
      trailing: l10n.progressWeeklySpan,
      child: Semantics(
        container: true,
        label: l10n.progressWeeklyLabel(counts.join(', ')),
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: _gap,
          children: [
            for (final (index, monday) in mondays.indexed)
              Expanded(
                child: _WeekColumn(
                  barHeight: counts[index] == 0
                      ? _emptyBar
                      : max(_emptyBar, _plotHeight * counts[index] / highest),
                  label: dayMonth.format(monday),
                  isCurrent: index == mondays.length - 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Une colonne posée sur la ligne de base, sa date en dessous.
class _WeekColumn extends StatelessWidget {
  const _WeekColumn({
    required this.barHeight,
    required this.label,
    required this.isCurrent,
  });

  final double barHeight;
  final String label;

  /// La semaine en cours ressort ; les précédentes restent en retrait.
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        SizedBox(
          height: _WeeklyJournalsChart._plotHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: barHeight,
              decoration: BoxDecoration(
                borderRadius: _WeeklyJournalsChart._barRadius,
                color: isCurrent
                    ? scheme.primary
                    : scheme.primary.withValues(
                        alpha: _WeeklyJournalsChart._pastOpacity,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: _WeeklyJournalsChart._labelGap),
        // La date reste dans sa colonne, même en très grands caractères.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0,
              color: isCurrent ? scheme.onSurface : scheme.onSurfaceVariant,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

/// Barres horizontales classées, une couleur, le nombre en bout de ligne.
class _MistakesByCategory extends StatelessWidget {
  const _MistakesByCategory({required this.counts});

  final List<CategoryCount> counts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final highest = counts.fold(0, (most, entry) => max(most, entry.count));

    return _Section(
      title: l10n.progressMistakesTitle,
      child: counts.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(l10n.progressMistakesEmpty),
            )
          : Column(
              children: [
                for (final entry in counts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: MergeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  errorCategoryName(l10n, entry.category),
                                ),
                              ),
                              Text(
                                '${entry.count}',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SoftProgressBar(value: entry.count / highest),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Gratuit : ce que Premium ajoute. Le bouton vers les offres n'apparaît
/// qu'après une première correction (ADR-040).
class _PremiumTeaser extends ConsumerWidget {
  const _PremiumTeaser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final onWarm = theme.colorScheme.onSecondaryContainer;

    return SoftCard(
      color: theme.colorScheme.secondaryContainer,
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const IconBadge(Icons.insights_outlined, accent: true),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.progressPremiumTitle,
                    style: theme.textTheme.titleMedium?.copyWith(color: onWarm),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.progressPremiumBody,
            style: theme.textTheme.bodyMedium?.copyWith(color: onWarm),
          ),
          if (watchHasCorrectedJournal(ref)) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => context.push(AppRoutes.paywall),
              child: Text(l10n.paywallDiscover),
            ),
          ],
        ],
      ),
    );
  }
}
