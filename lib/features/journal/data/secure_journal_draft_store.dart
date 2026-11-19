import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../languages/domain/learning_language.dart';
import '../domain/journal_draft_store.dart';

/// Brouillons chiffrés par le Keystore / Keychain : un journal est un texte
/// personnel, il ne reste pas en clair sur l'appareil.
class SecureJournalDraftStore implements JournalDraftStore {
  const SecureJournalDraftStore([this._storage = const FlutterSecureStorage()]);

  static const _keyPrefix = 'journal_draft_';

  final FlutterSecureStorage _storage;

  String _key(String userId, LearningLanguage language) =>
      '$_keyPrefix${userId}_${language.code}';

  @override
  Future<String> load(String userId, LearningLanguage language) async =>
      await _storage.read(key: _key(userId, language)) ?? '';

  @override
  Future<void> save(String userId, LearningLanguage language, String text) {
    final key = _key(userId, language);
    return text.isEmpty
        ? _storage.delete(key: key)
        : _storage.write(key: key, value: text);
  }

  @override
  Future<void> clearAll() async {
    final entries = await _storage.readAll();
    for (final key in entries.keys.where((key) => key.startsWith(_keyPrefix))) {
      await _storage.delete(key: key);
    }
  }
}
