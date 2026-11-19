import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Conserve la session Supabase dans le Keystore (Android) / Keychain (iOS)
/// plutôt que dans les préférences en clair.
class SecureLocalStorage extends LocalStorage {
  const SecureLocalStorage([this._storage = const FlutterSecureStorage()]);

  static const _sessionKey = 'supabase_session';

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _sessionKey);

  @override
  Future<String?> accessToken() => _storage.read(key: _sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _sessionKey, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _sessionKey);
}
