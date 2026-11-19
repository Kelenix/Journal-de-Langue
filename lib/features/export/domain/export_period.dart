/// Période couverte par un export des révisions (US-17).
enum ExportPeriod {
  lastWeek(days: 7),
  lastMonth(days: 30),
  allTime(days: null);

  const ExportPeriod({required this.days});

  /// Nombre de jours, aujourd'hui compris ; `null` pour tout l'historique.
  final int? days;

  /// Premier jour couvert quand on est le [today], ou `null` sans limite.
  DateTime? firstDay(DateTime today) {
    final days = this.days;
    if (days == null) return null;
    return DateTime(today.year, today.month, today.day - (days - 1));
  }
}
