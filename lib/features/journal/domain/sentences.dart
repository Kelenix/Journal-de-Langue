/// Une phrase se termine par . ! ? … ou un retour à la ligne.
/// Même règle que `count_sentences` côté serveur, qui fait foi
/// (supabase/migrations/20261119150000_journal_and_corrections.sql).
final _sentenceBoundary = RegExp(r'[.!?…]+|[\n\r]+');

int countSentences(String text) => text
    .split(_sentenceBoundary)
    .where((segment) => segment.trim().isNotEmpty)
    .length;
