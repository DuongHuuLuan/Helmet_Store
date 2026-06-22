import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:dartz/dartz.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getAllProduct({
    int? categoryId,
    int? page,
    int? perPage,
    String? keyword,
  });
  Future<Either<Failure, Product>> productDetail(int id);
}
