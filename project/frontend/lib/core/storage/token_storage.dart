import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Abstraction over "where the admin bearer token lives". Keeps
/// `flutter_secure_storage` out of every other file — swap the
/// implementation (e.g. for tests, or a different backing store) without
/// touching DioClient or any feature code.
abstract class TokenStorage {
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
}

class SecureTokenStorage implements TokenStorage {
  static const _tokenKey = AppConstants.authTokenStorageKey;

  final FlutterSecureStorage _storage;

  SecureTokenStorage(this._storage);

  factory SecureTokenStorage.create() {
    return SecureTokenStorage(
      const FlutterSecureStorage(
        // encryptedSharedPreferences uses Android Keystore-backed AES
        // encryption instead of plain SharedPreferences under the hood.
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      ),
    );
  }

  @override
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
