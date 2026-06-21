import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorageService {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<void> deleteAccessToken();

  Future<void> saveLastRoute(String route);
  Future<String?> getLastRoute();
  Future<void> deleteLastRoute();

  Future<void> savePushToken(String token);
  Future<String?> getPushToken();
  Future<void> deletePushToken();
}

class SecureStorageImpl implements SecureStorageService {
  static const _accessTokenKey = "access_token";
  static const _lastRouteKey = "last_route";
  static const _pushTokenKey = "push_token";

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  @override
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  @override
  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  @override
  Future<void> saveLastRoute(String route) async {
    await _storage.write(key: _lastRouteKey, value: route);
  }

  @override
  Future<String?> getLastRoute() async {
    return await _storage.read(key: _lastRouteKey);
  }

  @override
  Future<void> deleteLastRoute() async {
    await _storage.delete(key: _lastRouteKey);
  }

  @override
  Future<void> savePushToken(String token) async {
    await _storage.write(key: _pushTokenKey, value: token);
  }

  @override
  Future<String?> getPushToken() async {
    return await _storage.read(key: _pushTokenKey);
  }

  @override
  Future<void> deletePushToken() async {
    await _storage.delete(key: _pushTokenKey);
  }
}
