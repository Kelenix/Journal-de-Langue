import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/presentation/failure_message.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/surfaces.dart';
import '../application/vocabulary_providers.dart';
import '../domain/vocabulary_item.dart';

/// Cartes du jour : les mots à réviser, un à la fois. On se rappelle la
/// traduction avant de la voir, puis on répond « Je sais » (le mot est
/// appris) ou « À revoir » (il reste à réviser).
class DailyCard extends ConsumerStatefulWidget {
  const DailyCard({required this.words, super.key});

  /// Tout le vocabulaire, dans l'ordre de la liste.
  final List<VocabularyItem> words;

  @override
  ConsumerState<DailyCard> createState() => _DailyCardState();
}

class _DailyCardState extends ConsumerState<DailyCard>
    with AutomaticKeepAliveClientMixin {
  static const _deckSize = 5;
  static const _doneBadgeSize = 56.0;
  static const _revealButtonHeight = 44.0;
  static const _termSize = 32.0;
  static const _exampleSize = 15.0;
  static const _answerHeight = 50.0;
  static const _answerRadius = Radius.circular(16);
  // Marge réduite : « Je la connais » tient sur une ligne.
  static const _answerPadding = EdgeInsets.symmetric(horizontal: AppSpacing.md);

  /// Mots du paquet en cours, fixés à son ouverture.
  late List<String> _deck = _newDeck();

  /// Position à partir de laquelle chercher la carte à afficher.
  int _index = 0;

  /// Mot dont la traduction est visible.
  String? _revealedId;
  bool _isSaving = false;

  // Le paquet survit au défilement de la liste qui le contient.
  @override
  bool get wantKeepAlive => true;

  List<String> _newDeck() => [
    for (final word in widget.words)
      if (word.learnedAt == null) word.id,
  ].take(_deckSize).toList();

  @override
  void didUpdateWidget(DailyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Des mots arrivent (journal corrigé) alors qu'il n'y avait rien à
    // réviser, ou aucun mot du paquet n'est plus dans la liste (autre langue).
    final ids = {for (final word in widget.words) word.id};
    if (_deck.isEmpty || !_deck.any(ids.contains)) {
      _deck = _newDeck();
      _index = 0;
      _revealedId = null;
    }
  }

  void _restart() => setState(() {
    _deck = _newDeck();
    _index = 0;
  });

  Future<void> _markKnown(VocabularyItem word) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);
    try {
      // Le mot appris quitte le paquet : la carte suivante s'affiche.
      await ref
          .read(vocabularyProvider.notifier)
          .setLearned(word, isLearned: true);
    } on Failure catch (failure) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, failure))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_deck.isEmpty) return const SizedBox.shrink();

    final toReview = {
      for (final word in widget.words)
        if (word.learnedAt == null) word.id: word,
    };
    // La carte affichée : la prochaine du paquet encore à réviser.
    int? position;
    for (var candidate = _index; candidate < _deck.length; candidate++) {
      if (toReview.containsKey(_deck[candidate])) {
        position = candidate;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: SoftCard(
        radius: AppRadius.sheet,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: position == null
            ? _Done(hasMore: toReview.isNotEmpty, onRestart: _restart)
            : _card(context, toReview[_deck[position]]!, position),
      ),
    );
  }

  Widget _card(BuildContext context, VocabularyItem word, int position) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.reviewCardOf(position + 1, _deck.length).toUpperCase(),
          semanticsLabel: l10n.reviewCardOf(position + 1, _deck.length),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: muted,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Annoncé à chaque nouvelle carte.
        Semantics(
          liveRegion: true,
          child: Text(
            word.term,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: _termSize,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          word.example,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: _exampleSize,
            color: muted,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_revealedId == word.id)
          Text(
            word.translation,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          )
        else
          // Bordure en pointillés : on devine d'abord, on vérifie ensuite.
          Center(
            child: CustomPaint(
              painter: _DashedPillPainter(theme.colorScheme.outline),
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, _revealButtonHeight),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  shape: const StadiumBorder(),
                  textStyle: theme.textTheme.labelLarge,
                ),
                onPressed: () => setState(() => _revealedId = word.id),
                child: Text(l10n.reviewShowTranslation),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(_answerHeight),
                  padding: _answerPadding,
                  backgroundColor: theme.cardColor,
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(_answerRadius),
                  ),
                ),
                onPressed: _isSaving
                    ? null
                    : () => setState(() => _index = position + 1),
                child: Text(l10n.reviewAgain, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(_answerHeight),
                  padding: _answerPadding,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(_answerRadius),
                  ),
                ),
                onPressed: _isSaving ? null : () => _markKnown(word),
                child: Text(l10n.reviewKnown, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Paquet terminé : un mot d'encouragement, et d'autres cartes s'il reste des
/// mots à réviser.
class _Done extends StatelessWidget {
  const _Done({required this.hasMore, required this.onRestart});

  final bool hasMore;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: IconBadge(
            Icons.emoji_events_outlined,
            size: _DailyCardState._doneBadgeSize,
            accent: true,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          liveRegion: true,
          child: Text(
            l10n.reviewDeckDone,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (hasMore) ...[
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: onRestart,
            child: Text(l10n.reviewDeckMore),
          ),
        ],
      ],
    );
  }
}

/// Contour en pointillés d'une pilule.
class _DashedPillPainter extends CustomPainter {
  const _DashedPillPainter(this.color);

  static const _dash = 4.0;
  static const _gap = 3.0;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.height / 2),
        ),
      );
    for (final metric in outline.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += _dash + _gap) {
        canvas.drawPath(metric.extractPath(start, start + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPillPainter oldDelegate) =>
      oldDelegate.color != color;
}
