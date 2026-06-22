import 'package:b2205946_duonghuuluan_luanvan/presentation/auth/cubit/register_state.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/auth/register_usecase.dart';
import 'package:bloc/bloc.dart';


class RegisterCubit extends Cubit<RegisterState> {
  final RegisterUseCase _register;
  RegisterCubit(this._register) : super(const RegisterState());

  Future<bool> register({
    required String email,
    required String username,
    required String password,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await _register({
      "email": email,
      "username": username,
      "password": password,
    });
    return result.fold(
      (failure) {
        emit(state.copyWith(isLoading: false, errorMessage: failure.message));
        return false;
      },
      (_) {
        emit(state.copyWith(isLoading: false, errorMessage: null));
        return true;
      },
    );
  }
}
