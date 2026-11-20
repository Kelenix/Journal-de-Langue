import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/presentation/failure_message.dart';
import '../application/ads_providers.dart';
import '../domain/ad_status.dart';

/// Bannière discrète, montrée seulement à qui voit des publicités (US-22).
class AdBanner extends ConsumerWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!watchAdsVisible(ref)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Center(child: ref.watch(adsServiceProvider).banner()),
    );
  }
}

/// Propose une vidéo pour obtenir [kind] (US-23).
class RewardedAdButton extends ConsumerStatefulWidget {
  const RewardedAdButton({
    required this.kind,
    required this.onReload,
    super.key,
  });

  final AdRewardKind kind;

  /// Recharge ce que la récompense débloque : une fois accordée par le
  /// serveur, ou à la demande si sa confirmation tarde.
  final VoidCallback onReload;

  @override
  ConsumerState<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends ConsumerState<RewardedAdButton> {
  bool _isWatching = false;

  Future<void> _watch() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isWatching = true);
    final RewardResult result;
    try {
      result = await ref
          .read(adsControllerProvider.notifier)
          .watchRewarded(widget.kind);
    } on Failure catch (failure) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(l10n, failure))),
      );
      return;
    } finally {
      // Le bouton revient, même après un échec.
      if (mounted) setState(() => _isWatching = false);
    }
    if (!mounted) return;

    final message = switch (result) {
      RewardResult.granted => l10n.rewardGranted,
      RewardResult.pending => l10n.rewardPending,
      RewardResult.notEarned => l10n.rewardNotEarned,
      RewardResult.unavailable => l10n.rewardUnavailable,
    };
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        // La confirmation d'AdMob peut arriver plus tard : de quoi vérifier.
        action: result == RewardResult.pending
            ? SnackBarAction(label: l10n.rewardRefresh, onPressed: _reload)
            : null,
      ),
    );
    if (result == RewardResult.granted) widget.onReload();
  }

  void _reload() {
    if (!mounted) return;
    ref.invalidate(adStatusProvider);
    widget.onReload();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(adStatusProvider).value;
    if (status == null || !status.canWatchFor(widget.kind)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);

    return TextButton.icon(
      icon: _isWatching
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.ondemand_video_outlined),
      label: Text(switch (widget.kind) {
        AdRewardKind.correction => l10n.rewardWatchForCorrection,
        AdRewardKind.exercises => l10n.rewardWatchForExercises,
      }),
      onPressed: _isWatching ? null : _watch,
    );
  }
}
