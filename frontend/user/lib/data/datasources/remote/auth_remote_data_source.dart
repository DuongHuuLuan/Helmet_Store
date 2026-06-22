import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/auth/auth_result_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/auth/user_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/auth_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/auth/auth_result.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/auth/user.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class AuthRemoteDataSource {
  final AuthService _service;
  AuthRemoteDataSource(this._service);
  Future<Either<Failure, AuthResult>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _service.login(email, password);
      return Right(AuthResultMapper.fromResponse(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, Unit>> register(Map<String, dynamic> data) async {
    try {
      await _service.register(data);
      return Right(unit);
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, User>> getMe() async {
    try {
      final response = await _service.getMe();
      return Right(UserMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }
}
