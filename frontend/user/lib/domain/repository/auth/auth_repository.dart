import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/auth/auth_result.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/auth/user.dart';
import 'package:dartz/dartz.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResult>> login(String email, String password);

  Future<Either<Failure, Unit>> register(Map<String, dynamic> data);
  Future<Either<Failure, User>> getMe();
  Future<void> logout();
  // check xem có token trong may chưa (dùng cho auto-login)
  Future<bool> checkAuthStatus();
}
