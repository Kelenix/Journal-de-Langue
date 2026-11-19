import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/utils/dates.dart';
import '../../languages/domain/learning_language.dart';
import '../domain/journal_entry.dart';
import '../domain/journal_repository.dart';

class SupabaseJournalRepository implements JournalRepository {
  const SupabaseJournalRepository(this._client);

  static const _entryColumns =
      'id, language, entry_date, original_text, corrected_text, '
      'correction_items(position, original, corrected, category, explanation)';

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
    final row = await _entries()
        .eq('entry_date', isoDate(day))
        .order('corrected_at', ascending: false)
        .order('position', referencedTable: 'correction_items', ascending: true)
        .limit(1)
        .maybeSingle();
    return row == null ? null : JournalEntry.fromJson(row);
  });

  @override
  Future<JournalEntry> entry(String id) => guardFailures(() async {
    final row = await _entries()
        .eq('id', id)
        .order('position', referencedTable: 'correction_items', ascending: true)
        .single();
    return JournalEntry.fromJson(row);
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

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _entries() =>
      _client.from('journal_entries').select(_entryColumns);
}
