/// Portion d'un texte, marquée ou non.
typedef TextSegment = ({String text, bool isHighlighted});

/// Découpe [text] en marquant, dans l'ordre, la première occurrence restante de
/// chaque élément de [fragments]. Un fragment introuvable est ignoré : le texte
/// est toujours restitué en entier.
List<TextSegment> highlightFragments(String text, List<String> fragments) {
  final segments = <TextSegment>[];
  var cursor = 0;

  for (final fragment in fragments) {
    if (fragment.isEmpty) continue;
    final start = text.indexOf(fragment, cursor);
    if (start < 0) continue;
    if (start > cursor) {
      segments.add((text: text.substring(cursor, start), isHighlighted: false));
    }
    segments.add((text: fragment, isHighlighted: true));
    cursor = start + fragment.length;
  }

  if (cursor < text.length) {
    segments.add((text: text.substring(cursor), isHighlighted: false));
  }
  return segments;
}
