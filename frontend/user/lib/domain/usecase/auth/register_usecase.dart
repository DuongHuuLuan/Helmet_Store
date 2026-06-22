import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/auth/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repo;
  RegisterUseCase(this._repo);
  Future<Either<Failure, Unit>> call(Map<String, dynamic> data) => _repo.register(data);
}
