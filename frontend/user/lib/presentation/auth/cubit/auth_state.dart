import 'package:b2205946_duonghuuluan_luanvan/domain/entity/auth/user.dart';
import 'package:equatable/equatable.dart';

class AuthState extends Equatable {
  final User? user;
  final bool isInitialized;

  const AuthState({this.user, this.isInitialized = false});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isInitialized,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  List<Object?> get props => [user, isInitialized];
}
