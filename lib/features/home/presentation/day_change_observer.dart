import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/clock.dart';
import '../../journal/application/journal_providers.dart';
import '../../stats/application/stats_providers.dart';

/// Recharge ce qui dépend du jour quand il change alors que l'app reste
/// ouverte : à minuit, ou au retour au premier plan un autre jour. Sans cela, le
/// journal garderait la limite d'hier (« correction du jour utilisée »).
class DayChangeObserver extends ConsumerStatefulWidget {
  const DayChangeObserver({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<DayChangeObserver> createState() => _DayChangeObserverState();
}

class _DayChangeObserverState extends ConsumerState<DayChangeObserver> {
  // Le minuteur ne part pas juste avant minuit.
  static const _margin = Duration(seconds: 1);

  late final AppLifecycleListener _lifecycle;
  late DateTime _day;
  Timer? _midnight;

  @override
  void initState() {
    super.initState();
    _day = _today();
    _lifecycle = AppLifecycleListener(onResume: _checkDay);
    _scheduleMidnight();
  }

  @override
  void dispose() {
    _midnight?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  DateTime _today() => DateUtils.dateOnly(ref.read(clockProvider)());

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = ref.read(clockProvider)();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(nextDay.difference(now) + _margin, _checkDay);
  }

  void _checkDay() {
    _scheduleMidnight();
    final today = _today();
    if (today == _day) return;
    _day = today;
    // Observés par des écrans seulement : une invalidation suffit (ADR-022).
    ref
      ..invalidate(journalDayProvider)
      ..invalidate(statsProvider)
      ..invalidate(historyOverviewProvider)
      ..invalidate(journalHistoryProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
