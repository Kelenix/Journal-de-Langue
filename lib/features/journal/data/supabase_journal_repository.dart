import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/utils/dates.dart';
import '../../languages/domain/learning_language.dart';
import '../domain/journal_entry.dart';
import '../domain/journal_repository.dart';

typedef _Rows = List<Map<String, dynamic>>;

class SupabaseJournalRepository implements JournalRepository {
  const SupabaseJournalRepository(this._client);

  static const _historyColumns =
      'id, language, entry_date, original_text, corrected_text, level, '
      'correction_items(position, original, corrected, category, explanation)';
  static const _entryColumns =
      '$_historyColumns, '
      'vocabulary_items(id, term, translation, example, learned_at)';

  /// Lignes par requête, sous la limite de l'API (`max_rows`).
  static const _batchSize = 200;

  /// Au-delà du plus long appel à Claude côté serveur (ADR-041) : une connexion
  /// morte sans erreur ne laisse pas l'écran attendre indéfiniment.
  static const _correctionTimeout = Duration(seconds: 150);
  static const _rewriteTimeout = Duration(seconds: 60);

  final SupabaseClient _client;

  @override
  Future<JournalAllowance> allowance(DateTime day) => guardFailures(() async {
    final entitlements = await _client.rpc<Map<String, dynamic>>(
      'get_entitlements',
      params: {'p_entry_date': isoDate(day)},
    );
    return JournalAllowance.fromJson(entitlements);
  });

  @override
  Future<String?> entryIdOfDay(DateTime day) => guardFailures(() async {
    final row = await _client
        .from('journal_entries')
        .select('id')
        .eq('entry_date', isoDate(day))
        .order('corrected_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row?['id'] as String?;
  });

  @override
  Future<JournalEntry> entry(String id) => guardFailures(() async {
    final row = await _detailsInOrder(_entries().eq('id', id)).single();
    return JournalEntry.fromJson(row);
  });

  @override
  Future<List<JournalEntry>> historyPage({
    required int offset,
    required int limit,
  }) => guardFailures(() async {
    final rows =
        await _mostRecentFirst(
              _client.from('journal_entries').select(_historyColumns),
            )
            .order(
              'position',
              referencedTable: 'correction_items',
              ascending: true,
            )
            .range(offset, offset + limit - 1);
    return rows.map(JournalEntry.fromJson).toList();
  });

  @override
  Future<List<JournalEntry>> entriesSince(
    LearningLanguage language, {
    DateTime? firstDay,
  }) => guardFailures(() async {
    final entries = <JournalEntry>[];
    while (true) {
      var query = _entries().eq('language', language.code);
      if (firstDay != null) query = query.gte('entry_date', isoDate(firstDay));
      final rows = await _detailsInOrder(
        _mostRecentFirst(query),
      ).range(entries.length, entries.length + _batchSize - 1);
      entries.addAll(rows.map(JournalEntry.fromJson));
      if (rows.length < _batchSize) return entries;
    }
  });

  @override
  Future<HistoryOverview> historyOverview() => guardFailures(() async {
    final overview = await _client.rpc<Map<String, dynamic>>(
      'get_history_overview',
    );
    return HistoryOverview.fromJson(overview);
  });

  @override
  Future<SentenceRewrite> rewrite({
    required String entryId,
    required String sentence,
  }) => guardFailures(() async {
    final response = await _client.functions
        .invoke(
          'rewrite-sentence',
          body: {'entry_id': entryId, 'sentence': sentence},
        )
        .timeout(_rewriteTimeout);
    return SentenceRewrite.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<JournalEntry> submit({
    required String text,
    required LearningLanguage language,
    required String uiLocale,
    required DateTime day,
    required String idempotencyKey,
  }) => guardFailures(() async {
    final response = await _client.functions
        .invoke(
          'correct-entry',
          body: {
            'text': text,
            'language': language.code,
            'ui_locale': uiLocale,
            'local_date': isoDate(day),
            'idempotency_key': idempotencyKey,
          },
        )
        .timeout(_correctionTimeout);
    return JournalEntry.fromJson(response.data as Map<String, dynamic>);
  });

  /// Journaux que l'utilisateur peut lire (la RLS applique son offre).
  PostgrestFilterBuilder<_Rows> _entries() =>
      _client.from('journal_entries').select(_entryColumns);

  /// Ordre stable d'une page à l'autre.
  PostgrestTransformBuilder<_Rows> _mostRecentFirst(
    PostgrestFilterBuilder<_Rows> query,
  ) => query
      .order('entry_date', ascending: false)
      .order('corrected_at', ascending: false)
      .order('id', ascending: false);

  /// Range les fautes et le vocabulaire de chaque journal dans l'ordre
  /// d'affichage.
  PostgrestTransformBuilder<_Rows> _detailsInOrder(
    PostgrestTransformBuilder<_Rows> query,
  ) => query
      .order('position', referencedTable: 'correction_items', ascending: true)
      .order('created_at', referencedTable: 'vocabulary_items', ascending: true)
      .order('term', referencedTable: 'vocabulary_items', ascending: true);
}
