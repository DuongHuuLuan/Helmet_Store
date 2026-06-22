import 'package:b2205946_duonghuuluan_luanvan/presentation/auth/cubit/auth_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/auth/cubit/login_state.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/auth/login_usecase.dart';
import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:b2205946_duonghuuluan_luanvan/injection_container.dart' as di;

class LoginCubit extends Cubit<LoginState> {
  final LoginUseCase _loginUseCase;
  final AuthCubit _authCubit;
  final SharedPreferences _prefs;
  LoginCubit(this._loginUseCase, this._authCubit)
      : _prefs = di.getIt<SharedPreferences>(),
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
        await _prefs.setString("access_token", authResult.accessToken);
        await _prefs.setString("refresh_token", authResult.refreshToken);
        _authCubit.setAuth(authResult.user);
        emit(state.copyWith(isLoading: false, errorMessage: ''));
        return true;
      },
    );
  }
}
