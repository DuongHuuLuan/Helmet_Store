import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  final bool isLoading;
  final String errorMessage;
  const LoginState({this.isLoading = false, this.errorMessage = ''});

  LoginState copyWith({bool? isLoading, String? errorMessage}) => LoginState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [isLoading, errorMessage];
}
