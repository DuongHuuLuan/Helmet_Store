import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/profile/profile.dart';
import 'package:dartz/dartz.dart';

abstract class ProfileRepository {
  Future<Either<Failure, Profile>> getProfile();
  Future<Either<Failure, Profile>> updateProfile(Map<String, dynamic> data);
  Future<Either<Failure, Profile>> uploadAvatar({required String filePath, String? fileName});
}
