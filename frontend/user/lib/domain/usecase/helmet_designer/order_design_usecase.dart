import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/helmet_designer/helmet_designer_repository.dart';

class OrderDesignUseCase {
  final HelmetDesignerRepository _repo;
  OrderDesignUseCase(this._repo);
  Future<Either<Failure, Unit>> call(int designId, {required int productDetailId, int quantity = 1}) =>
      _repo.orderDesign(designId, productDetailId: productDetailId, quantity: quantity);
}
