import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/profile/profile.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/profile/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository _repo;
  UpdateProfileUseCase(this._repo);
  Future<Either<Failure, Profile>> call(Map<String, dynamic> data) => _repo.updateProfile(data);
}
