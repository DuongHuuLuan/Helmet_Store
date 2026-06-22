import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/helmet_design.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/helmet_designer/helmet_designer_repository.dart';

class SaveDesignUseCase {
  final HelmetDesignerRepository _repo;
  SaveDesignUseCase(this._repo);
  Future<Either<Failure, HelmetDesign>> call(HelmetDesign design) => _repo.saveDesign(design);
}
