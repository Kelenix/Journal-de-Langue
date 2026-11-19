/// Une phrase se termine par . ! ? … ou un retour à la ligne.
/// Même règle que `count_sentences` côté serveur, qui fait foi
/// (supabase/migrations/20261119150000_journal_and_corrections.sql).
final _sentenceBoundary = RegExp(r'[.!?…]+|[\n\r]+');

final _sentence = RegExp(r'[^.!?…\n\r]+[.!?…]*');

/// Phrases de [text], chacune avec sa ponctuation finale, telles qu'elles y
/// figurent.
List<String> splitSentences(String text) => _sentence
    .allMatches(text)
    .map((match) => match.group(0)!.trim())
    .where((sentence) => sentence.isNotEmpty)
    .toList();

int countSentences(String text) => text
    .split(_sentenceBoundary)
    .where((segment) => segment.trim().isNotEmpty)
    .length;
