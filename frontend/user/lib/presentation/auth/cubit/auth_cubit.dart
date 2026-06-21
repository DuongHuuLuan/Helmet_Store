import 'package:b2205946_duonghuuluan_luanvan/core/notifications/push_notification_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/auth/cubit/auth_state.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/auth/check_auth_status_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/auth/get_current_user_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/auth/logout_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/auth/user.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';


class AuthCubit extends Cubit<AuthState> {
  final CheckAuthStatusUseCase _checkAuthStatus;
  final GetCurrentUserUseCase _getCurrentUser;
  final LogoutUseCase _logout;

  AuthCubit(this._checkAuthStatus, this._getCurrentUser, this._logout)
    : super(const AuthState()) {
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      debugPrint("AuthCubit: bắt đầu khởi động");
      final hasToken = await _checkAuthStatus();
      debugPrint("AuthCubit: hasToken=$hasToken");

      if (!hasToken) {
        emit(state.copyWith(isInitialized: true));
        return;
      }

      final meResult = await _getCurrentUser();
      await meResult.fold(
        (failure) async {
          debugPrint(
            "AuthCubit: phiên đăng nhập đã hết hạn hoặc lỗi: ${failure.message}",
          );
          await _clearSession();
          emit(state.copyWith(user: null, isInitialized: true));
        },
        (user) async {
          debugPrint(
            "AuthCubit: phiên đăng nhập đã được khôi phục cho ${user.username}",
          );
          emit(state.copyWith(user: user, isInitialized: true));
        },
      );
    } catch (e) {
      debugPrint("AuthCubit: lỗi khởi tạo hệ thống $e");
      emit(state.copyWith(isInitialized: true));
    }
  }

  void setAuth(User user) {
    emit(state.copyWith(user: user, isInitialized: true));
  }

  /// Tách hàm xóa session riêng để dùng nội bộ, tránh loop emit
  Future<void> _clearSession() async {
    try {
      await PushNotificationService.instance.deactivateCurrentDevice();
    } catch (e) {
      debugPrint("AuthCubit: lỗi hủy push notification: $e");
    }
    await _logout();
  }

  Future<void> logout() async {
    await _clearSession();
    emit(state.copyWith(user: null));
  }
}
