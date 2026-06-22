import 'package:b2205946_duonghuuluan_luanvan/core/constants/api_endpoints.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:b2205946_duonghuuluan_luanvan/injection_container.dart';
import 'package:dio/dio.dart';

class PushNotificationApi {
  final Dio _dio = getIt<Dio>();

  Future<void> registerDevice({
    required String platform,
    required String pushToken,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.pushDevices,
        data: {
          "platform": platform,
          "push_token": pushToken,
        },
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deactivateDevice(String pushToken) async {
    try {
      await _dio.delete(
        ApiEndpoints.pushDevices,
        queryParameters: {
          "push_token": pushToken,
        },
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
