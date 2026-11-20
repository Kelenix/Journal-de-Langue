import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_de_langue/features/journal/data/secure_journal_draft_store.dart';
import 'package:journal_de_langue/features/languages/domain/learning_language.dart';

/// Brouillons du journal dans le stockage chiffré de l'appareil (US-05), à
/// côté de la session, qui ne doit jamais être touchée.
void main() {
  const store = SecureJournalDraftStore();
  const session = {'session': 'jeton'};

  setUp(() => FlutterSecureStorage.setMockInitialValues({...session}));

  Future<Map<String, String>> stored() =>
      const FlutterSecureStorage().readAll();

  test('un brouillon est gardé par utilisateur et par langue', () async {
    await store.save('user-1', LearningLanguage.english, 'Today I');

    expect(await store.load('user-1', LearningLanguage.english), 'Today I');
    expect(await store.load('user-1', LearningLanguage.spanish), isEmpty);
    expect(await store.load('user-2', LearningLanguage.english), isEmpty);
  });

  test('un brouillon vidé est effacé de l\'appareil', () async {
    await store.save('user-1', LearningLanguage.english, 'Today I');

    await store.save('user-1', LearningLanguage.english, '');

    expect(await stored(), session);
  });

  test('tout effacer retire les brouillons de toutes les langues, pas la '
      'session', () async {
    await store.save('user-1', LearningLanguage.english, 'Today I');
    await store.save('user-1', LearningLanguage.spanish, 'Hoy');

    await store.clearAll();

    expect(await stored(), session);
  });
}
