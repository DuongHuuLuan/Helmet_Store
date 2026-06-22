import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalDataSource {
  final SharedPreferences _prefs;

  AuthLocalDataSource(this._prefs);

  Future<void> saveAccessToken(String token) =>
      _prefs.setString("access_token", token);

  Future<String?> getAccessToken() async =>
      _prefs.getString("access_token");

  Future<void> deleteAccessToken() async =>
      _prefs.remove("access_token");

  Future<void> saveRefreshToken(String token) =>
      _prefs.setString("refresh_token", token);

  Future<String?> getRefreshToken() async =>
      _prefs.getString("refresh_token");

  Future<void> deleteRefreshToken() async =>
      _prefs.remove("refresh_token");
}
