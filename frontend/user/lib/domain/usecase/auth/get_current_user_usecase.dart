import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/auth/auth_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/auth/user.dart';

class GetCurrentUserUseCase {
  final AuthRepository _repo;
  GetCurrentUserUseCase(this._repo);
  Future<Either<Failure, User>> call() => _repo.getMe();
}
