import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/product/product_repository.dart';

class GetProductDetailUseCase {
  final ProductRepository _repo;
  GetProductDetailUseCase(this._repo);
  Future<Either<Failure, Product>> call(int id) => _repo.productDetail(id);
}
