import 'dart:convert';

import 'package:b2205946_duonghuuluan_luanvan/injection_container.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  bool _isRefreshing = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = getIt<SharedPreferences>();

    if (!options.path.contains('/auth/refresh')) {
      final token = prefs.getString("access_token");
      if (token != null) {
        final payload = _decodeJwtPayload(token);
        if (payload != null) {
          final exp = payload['exp'] as int?;
          if (exp != null) {
            final expTime = DateTime.fromMillisecondsSinceEpoch(
              exp * 1000,
              isUtc: true,
            );
            if (DateTime.now().toUtc().isAfter(
              expTime.subtract(const Duration(seconds: 30)),
            )) {
              final refreshToken = prefs.getString("refresh_token");
              if (refreshToken != null) {
                try {
                  final dio = getIt<Dio>();
                  final res = await dio.post(
                    '/auth/refresh',
                    data: {"refresh_token": refreshToken},
                  );
                  final newToken = res.data['access_token'] as String;
                  final newRefresh = res.data['refresh_token'] as String;
                  await prefs.setString("access_token", newToken);
                  await prefs.setString("refresh_token", newRefresh);
                  options.headers["Authorization"] = "Bearer $newToken";
                  handler.next(options);
                  return;
                } catch (_) {}
              }
            }
          }
        }
      }
    }

    final token = prefs.getString("access_token");
    if (token != null) {
      options.headers["Authorization"] = "Bearer $token";
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final prefs = getIt<SharedPreferences>();
        final refreshToken = prefs.getString("refresh_token");
        if (refreshToken != null) {
          final dio = getIt<Dio>();
          final res = await dio.post(
            '/auth/refresh',
            data: {"refresh_token": refreshToken},
          );
          final newToken = res.data['access_token'] as String;
          final newRefresh = res.data['refresh_token'] as String;
          await prefs.setString("access_token", newToken);
          await prefs.setString("refresh_token", newRefresh);
          err.requestOptions.headers["Authorization"] = "Bearer $newToken";
          final retryResponse = await dio.fetch(err.requestOptions);
          _isRefreshing = false;
          handler.resolve(retryResponse);
          return;
        }
      } catch (_) {
        final prefs = getIt<SharedPreferences>();
        await prefs.remove("access_token");
        await prefs.remove("refresh_token");
        await prefs.setBool('session_expired', true);
      }
      _isRefreshing = false;
    }
    handler.reject(err);
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      String payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = utf8.decode(base64.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
