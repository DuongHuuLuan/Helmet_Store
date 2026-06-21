import 'package:b2205946_duonghuuluan_luanvan/core/storage/secure_storage.dart';
import 'package:b2205946_duonghuuluan_luanvan/injection_container.dart' as di;
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  SecureStorageService get _storage => di.getIt<SecureStorageService>();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.contains('/auth/login/user') ||
        options.path.contains('/auth/login/admin') ||
        options.path.contains('/auth/register')) {
      return handler.next(options);
    }
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      print("Interceptor : Đã gắn token vào Header");
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      print(
        "Interceptor: Token hết hạn hoặc không hợp lệ, yêu cầu đăng nhập lại.",
      );
    }
    return handler.next(err);
  }
}
