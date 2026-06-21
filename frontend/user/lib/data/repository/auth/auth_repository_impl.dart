import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/local/auth_local_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/auth_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/auth/auth_result.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/auth/user.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/auth/auth_repository.dart';
import 'package:dartz/dartz.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<Either<Failure, AuthResult>> login(String email, String password) async {
    return await _remoteDataSource.login(email, password);
  }

  @override
  Future<Either<Failure, Unit>> register(Map<String, dynamic> data) async {
    return await _remoteDataSource.register(data);
  }

  @override
  Future<bool> checkAuthStatus() async {
    final token = await _localDataSource.getAccessToken();
    return token != null;
  }

  @override
  Future<Either<Failure, User>> getMe() async {
    return await _remoteDataSource.getMe();
  }

  @override
  Future<void> logout() async {
    await _localDataSource.deleteAccessToken();
  }
}
