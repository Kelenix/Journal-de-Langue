import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/utils/dates.dart';
import '../../languages/domain/learning_language.dart';
import '../domain/journal_entry.dart';
import '../domain/journal_repository.dart';

typedef _Rows = List<Map<String, dynamic>>;

class SupabaseJournalRepository implements JournalRepository {
  const SupabaseJournalRepository(this._client);

  static const _entryColumns =
      'id, language, entry_date, original_text, corrected_text, '
      'correction_items(position, original, corrected, category, explanation), '
      'vocabulary_items(id, term, translation, example, learned_at)';

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
  Future<JournalEntry?> entryOfDay(DateTime day) => guardFailures(() async {
    final row = await _detailsInOrder(
      _entries()
          .eq('entry_date', isoDate(day))
          .order('corrected_at', ascending: false),
    ).limit(1).maybeSingle();
    return row == null ? null : JournalEntry.fromJson(row);
  });

  @override
  Future<JournalEntry> entry(String id) => guardFailures(() async {
    final row = await _detailsInOrder(_entries().eq('id', id)).single();
    return JournalEntry.fromJson(row);
  });

  @override
  Future<List<JournalEntry>> recentEntries() => guardFailures(() async {
    final rows = await _detailsInOrder(
      _entries()
          .order('entry_date', ascending: false)
          .order('corrected_at', ascending: false),
    );
    return rows.map(JournalEntry.fromJson).toList();
  });

  @override
  Future<HistoryOverview> historyOverview() => guardFailures(() async {
    final overview = await _client.rpc<Map<String, dynamic>>(
      'get_history_overview',
    );
    return HistoryOverview.fromJson(overview);
  });

  @override
  Future<JournalEntry> submit({
    required String text,
    required LearningLanguage language,
    required String uiLocale,
    required DateTime day,
    required String idempotencyKey,
  }) => guardFailures(() async {
    final response = await _client.functions.invoke(
      'correct-entry',
      body: {
        'text': text,
        'language': language.code,
        'ui_locale': uiLocale,
        'local_date': isoDate(day),
        'idempotency_key': idempotencyKey,
      },
    );
    return JournalEntry.fromJson(response.data as Map<String, dynamic>);
  });

  /// Journaux que l'utilisateur peut lire (la RLS applique son offre).
  PostgrestFilterBuilder<_Rows> _entries() =>
      _client.from('journal_entries').select(_entryColumns);

  /// Range les fautes et le vocabulaire de chaque journal dans l'ordre
  /// d'affichage.
  PostgrestTransformBuilder<_Rows> _detailsInOrder(
    PostgrestTransformBuilder<_Rows> query,
  ) => query
      .order('position', referencedTable: 'correction_items', ascending: true)
      .order('created_at', referencedTable: 'vocabulary_items', ascending: true)
      .order('term', referencedTable: 'vocabulary_items', ascending: true);
}
