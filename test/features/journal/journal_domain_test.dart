import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/core/utils/dates.dart';
import 'package:journal_de_langue/core/utils/uuid.dart';
import 'package:journal_de_langue/features/journal/domain/journal_entry.dart';
import 'package:journal_de_langue/features/journal/domain/sentences.dart';
import 'package:journal_de_langue/features/journal/domain/text_highlight.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';

void main() {
  // Mêmes cas que supabase/tests/journal_and_corrections_test.sql : les deux
  // comptages doivent rester d'accord, le serveur faisant foi.
  group('countSentences', () {
    const cases = {
      '': 0,
      '  \n  ': 0,
      'Hello': 1,
      'One. Two! Three?': 3,
      'Wait... what?!': 2,
      'Line one\nLine two\r\n\r\nLine three': 3,
      '¿Qué tal? ¡Muy bien!': 2,
      'A. B. C. D. E. F. G. H.': 8,
    };

    for (final MapEntry(key: text, value: expected) in cases.entries) {
      test('${text.replaceAll('\n', r'\n').replaceAll('\r', r'\r')} → '
          '$expected', () {
        expect(countSentences(text), expected);
      });
    }
  });

  group('highlightFragments', () {
    String rendered(String text, List<String> fragments) => highlightFragments(
      text,
      fragments,
    ).map((s) => s.isHighlighted ? '[${s.text}]' : s.text).join();

    test('marque chaque fragment dans l\'ordre', () {
      expect(
        rendered('I has a cat. She are nice.', ['has', 'are']),
        'I [has] a cat. She [are] nice.',
      );
    });

    test('marque la bonne occurrence quand un fragment se répète', () {
      expect(rendered('a is a', ['a', 'a']), '[a] is [a]');
    });

    test('ignore un fragment introuvable et restitue tout le texte', () {
      expect(rendered('I has a cat.', ['absent', 'has']), 'I [has] a cat.');
      expect(rendered('No mistake here.', []), 'No mistake here.');
    });
  });

  test('isoDate écrit le jour sur 10 caractères', () {
    expect(isoDate(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
  });

  test('newUuid produit des identifiants v4 distincts', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final ids = {for (var i = 0; i < 50; i++) newUuid()};

    expect(ids, hasLength(50));
    expect(ids.every(pattern.hasMatch), isTrue);
  });

  test('JournalEntry.fromJson lit la réponse du serveur', () {
    final entry = JournalEntry.fromJson(const {
      'id': 'e1',
      'language': 'de',
      'entry_date': '2026-11-19',
      'original_text': 'Ich bin gegangen in die Schule.',
      'corrected_text': 'Ich bin in die Schule gegangen.',
      'correction_items': [
        {
          'position': 1,
          'original': 'gegangen in die Schule',
          'corrected': 'in die Schule gegangen',
          'category': 'phrasing',
          'explanation': 'Le participe se place en fin de phrase.',
        },
      ],
    });

    expect(entry.language, LearningLanguage.german);
    expect(entry.entryDate, DateTime(2026, 11, 19));
    expect(entry.items.single.category, ErrorCategory.phrasing);
  });
}
