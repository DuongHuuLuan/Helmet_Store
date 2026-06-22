import 'package:dio/dio.dart';

class Failure {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  factory Failure.fromDio(DioException e) {
    final data = e.response?.data;
    String msg;
    if (data is Map) {
      msg = (data['message'] ?? data['detail'] ?? data['error'] ?? 'Lỗi server')
          .toString()
          .trim();
      if (msg.isEmpty) msg = 'Lỗi server';
    } else if (data is String && data.trim().isNotEmpty) {
      msg = data.trim();
    } else {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
          msg = 'Kết nối quá thời gian';
        case DioExceptionType.receiveTimeout:
          msg = 'Server không phản hồi';
        case DioExceptionType.connectionError:
          msg = 'Không thể kết nối đến máy chủ';
        case DioExceptionType.cancel:
          msg = 'Yêu cầu đã bị hủy';
        default:
          msg = e.message ?? 'Lỗi không xác định';
      }
    }
    return Failure(message: msg, statusCode: e.response?.statusCode);
  }

  factory Failure.fromError(Object e) {
    if (e is DioException) return Failure.fromDio(e);
    return Failure(message: e.toString());
  }

  @override
  String toString() => message;
}
