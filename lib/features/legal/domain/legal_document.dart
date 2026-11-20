import 'dart:convert';

/// Textes légaux livrés avec l'app (`assets/legal`), en français et en anglais.
/// Les mêmes fichiers sont publiés à une adresse publique pour les stores.
enum LegalDocument {
  terms,
  privacy;

  /// Texte dans la langue de l'interface : français, sinon anglais.
  String assetPath(String languageCode) =>
      'assets/legal/${name}_${languageCode == 'fr' ? 'fr' : 'en'}.md';
}

enum LegalBlockKind { title, section, listItem, paragraph }

typedef LegalBlock = ({LegalBlockKind kind, String text});

/// Découpe un texte écrit en Markdown simple : titre `# `, sections `## `,
/// éléments de liste `- ` et paragraphes séparés par une ligne vide. Rien
/// d'autre n'est interprété.
List<LegalBlock> parseLegalText(String source) {
  final blocks = <LegalBlock>[];
  final paragraph = <String>[];
  void endParagraph() {
    if (paragraph.isEmpty) return;
    blocks.add((kind: LegalBlockKind.paragraph, text: paragraph.join(' ')));
    paragraph.clear();
  }

  for (final rawLine in const LineSplitter().convert(source)) {
    final line = rawLine.trim();
    final LegalBlock? block = line.startsWith('# ')
        ? (kind: LegalBlockKind.title, text: line.substring(2))
        : line.startsWith('## ')
        ? (kind: LegalBlockKind.section, text: line.substring(3))
        : line.startsWith('- ')
        ? (kind: LegalBlockKind.listItem, text: line.substring(2))
        : null;
    if (block == null && line.isNotEmpty) {
      paragraph.add(line);
      continue;
    }
    endParagraph();
    if (block != null) blocks.add(block);
  }
  endParagraph();
  return blocks;
}
