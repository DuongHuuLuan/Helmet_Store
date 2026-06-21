import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/helmet_design.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/helmet_designer/helmet_designer_repository.dart';

class GetDesignDetailUseCase {
  final HelmetDesignerRepository _repo;
  GetDesignDetailUseCase(this._repo);
  Future<Either<Failure, HelmetDesign>> call(int designId) => _repo.getDesignDetail(designId);
}
