import 'dart:io';
import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/profile/profile_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/profile_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/profile/profile.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class ProfileRemoteDataSource {
  final ProfileService _service;

  ProfileRemoteDataSource(this._service);

  Future<Either<Failure, Profile>> getProfile() async {
    try {
      final response = await _service.getProfile();
      return Right(ProfileMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, Profile>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _service.updateProfile(data);
      return Right(ProfileMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, Profile>> uploadAvatar({required String filePath, String? fileName}) async {
    try {
      final file = await MultipartFile.fromFile(
        filePath,
        filename: fileName ?? filePath.split(Platform.pathSeparator).last,
      );
      final response = await _service.uploadAvatar(file);
      return Right(ProfileMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, Unit>> changePassword(Map<String, dynamic> data) async {
    try {
      await _service.changePassword(data);
      return Right(unit);
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }
}
