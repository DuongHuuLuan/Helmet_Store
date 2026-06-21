import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/auth/auth_result.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/auth/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repo;
  LoginUseCase(this._repo);
  Future<Either<Failure, AuthResult>> call(String email, String password) => _repo.login(email, password);
}
