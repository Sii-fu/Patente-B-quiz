import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';

class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance = SecureStorageService._();

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  Future<void> writeString(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  Future<String?> readString(String key) {
    return _storage.read(key: key);
  }

  Future<void> writeBool(String key, bool value) {
    return _storage.write(key: key, value: value.toString());
  }

  Future<bool?> readBool(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) {
      return null;
    }

    return value.toLowerCase() == 'true';
  }

  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }

  Future<void> migrateSensitivePrefsToSecureStorage() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in AppConstants.sensitiveStorageKeys) {
      await _migrateKeyFromSharedPreferences(prefs, key);
    }
  }

  Future<void> migrateSupabaseAuthSessionFromSharedPreferences(
    String persistSessionKey,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateKeyFromSharedPreferences(prefs, persistSessionKey);
  }

  Future<void> _migrateKeyFromSharedPreferences(
    SharedPreferences prefs,
    String key,
  ) async {
    if (!prefs.containsKey(key)) {
      return;
    }

    final secureValue = await _storage.read(key: key);
    if (secureValue == null) {
      final value = prefs.get(key);
      if (value is bool) {
        await writeBool(key, value);
      } else if (value is String) {
        await writeString(key, value);
      } else if (value != null) {
        await writeString(key, value.toString());
      }
    }

    await prefs.remove(key);
  }

  LocalStorage createSupabaseSessionStorage({
    required String persistSessionKey,
  }) {
    return _SupabaseSecureLocalStorage(
      storage: _storage,
      persistSessionKey: persistSessionKey,
    );
  }

  GotrueAsyncStorage createSupabasePkceStorage() {
    return _SupabaseSecureGotrueAsyncStorage(storage: _storage);
  }
}

class _SupabaseSecureLocalStorage extends LocalStorage {
  _SupabaseSecureLocalStorage({
    required this.storage,
    required this.persistSessionKey,
  });

  final FlutterSecureStorage storage;
  final String persistSessionKey;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    final value = await storage.read(key: persistSessionKey);
    return value != null;
  }

  @override
  Future<String?> accessToken() {
    return storage.read(key: persistSessionKey);
  }

  @override
  Future<void> removePersistedSession() {
    return storage.delete(key: persistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) {
    return storage.write(key: persistSessionKey, value: persistSessionString);
  }
}

class _SupabaseSecureGotrueAsyncStorage extends GotrueAsyncStorage {
  _SupabaseSecureGotrueAsyncStorage({required this.storage});

  final FlutterSecureStorage storage;
  static const String _pkcePrefix = 'sb-pkce-';

  String _buildKey(String key) => '$_pkcePrefix$key';

  @override
  Future<String?> getItem({required String key}) {
    return storage.read(key: _buildKey(key));
  }

  @override
  Future<void> removeItem({required String key}) {
    return storage.delete(key: _buildKey(key));
  }

  @override
  Future<void> setItem({required String key, required String value}) {
    return storage.write(key: _buildKey(key), value: value);
  }
}
