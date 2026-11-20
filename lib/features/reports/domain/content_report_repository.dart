/// Contenu produit par l'IA que l'utilisateur peut signaler (ADR-034).
enum ReportedContent {
  correction('correction'),
  exercise('exercise'),
  exam('exam');

  const ReportedContent(this.code);

  final String code;
}

/// Signalements des contenus produits par l'IA. Échoue avec une `Failure`.
abstract interface class ContentReportRepository {
  /// Signale le contenu [targetId] : journal corrigé, exercice ou simulation.
  Future<void> report(
    ReportedContent content,
    String targetId, {
    String? comment,
  });
}
