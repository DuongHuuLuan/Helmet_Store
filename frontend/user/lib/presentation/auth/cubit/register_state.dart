import 'package:equatable/equatable.dart';

class RegisterState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  const RegisterState({this.isLoading = false, this.errorMessage});

  RegisterState copyWith({bool? isLoading, String? errorMessage}) =>
      RegisterState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [isLoading, errorMessage];
}
