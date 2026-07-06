import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/profile/profile.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/profile/profile_repository.dart';

class UploadAvatarUseCase {
  final ProfileRepository _repo;
  UploadAvatarUseCase(this._repo);
  Future<Either<Failure, Profile>> call({required String filePath, String? fileName}) =>
      _repo.uploadAvatar(filePath: filePath, fileName: fileName);
}
