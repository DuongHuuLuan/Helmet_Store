import 'package:b2205946_duonghuuluan_luanvan/core/storage/secure_storage.dart';
import 'package:b2205946_duonghuuluan_luanvan/injection_container.dart' as di;
import 'package:b2205946_duonghuuluan_luanvan/presentation/auth/cubit/auth_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/auth/cubit/login_state.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/auth/login_usecase.dart';
import 'package:bloc/bloc.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginUseCase _loginUseCase;
  final AuthCubit _authCubit;
  final SecureStorageService _storage;
  LoginCubit(this._loginUseCase, this._authCubit)
      : _storage = di.getIt<SecureStorageService>(),
        super(const LoginState());

  Future<bool> login(String email, String password) async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));
    final result = await _loginUseCase(email, password);
    return result.fold(
      (failure) {
        emit(state.copyWith(isLoading: false, errorMessage: failure.message));
        return false;
      },
      (authResult) async {
        await _storage.saveAccessToken(authResult.accessToken);
        _authCubit.setAuth(authResult.user);
        emit(state.copyWith(isLoading: false, errorMessage: ''));
        return true;
      },
    );
  }
}
