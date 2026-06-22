import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/product/product_repository.dart';

class GetProductsUseCase {
  final ProductRepository _repo;
  GetProductsUseCase(this._repo);
  Future<Either<Failure, List<Product>>> call({int? categoryId, int? page, int? perPage, String? keyword}) =>
      _repo.getAllProduct(categoryId: categoryId, page: page, perPage: perPage, keyword: keyword);
}
