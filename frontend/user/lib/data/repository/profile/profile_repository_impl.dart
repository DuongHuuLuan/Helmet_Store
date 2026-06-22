import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/profile_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/profile/profile.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/profile/profile_repository.dart';
import 'package:dartz/dartz.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, Profile>> getProfile() async {
    return await _remoteDataSource.getProfile();
  }

  @override
  Future<Either<Failure, Profile>> updateProfile(Map<String, dynamic> data) async {
    return await _remoteDataSource.updateProfile(data);
  }

  @override
  Future<Either<Failure, Profile>> uploadAvatar({
    required String filePath,
    String? fileName,
  }) async {
    return await _remoteDataSource.uploadAvatar(filePath: filePath, fileName: fileName);
  }
}
