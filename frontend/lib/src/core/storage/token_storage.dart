import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class TokenStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll(List<String> keys);

  factory TokenStorage.create({
    required SharedPreferences prefs,
    required FlutterSecureStorage secureStorage,
  }) {
    if (kIsWeb) return _WebTokenStorage(prefs);
    return _SecureTokenStorage(secureStorage);
  }
}

class _SecureTokenStorage implements TokenStorage {
  const _SecureTokenStorage(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      await _storage.delete(key: key);
    }
  }
}

class _WebTokenStorage implements TokenStorage {
  const _WebTokenStorage(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<String?> read(String key) async => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) async =>
      _prefs.setString(key, value);

  @override
  Future<void> delete(String key) async => _prefs.remove(key);

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
