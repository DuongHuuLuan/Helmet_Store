import 'package:b2205946_duonghuuluan_luanvan/core/storage/secure_storage.dart';

class AuthLocalDataSource {
  final SecureStorageService _storage;

  AuthLocalDataSource(this._storage);

  Future<void> saveAccessToken(String token) =>
      _storage.saveAccessToken(token);

  Future<String?> getAccessToken() => _storage.getAccessToken();

  Future<void> deleteAccessToken() => _storage.deleteAccessToken();
}
