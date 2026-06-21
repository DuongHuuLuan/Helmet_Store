import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/product_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/product/product_repository.dart';
import 'package:dartz/dartz.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  ProductRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Product>>> getAllProduct({
    int? categoryId,
    int? page,
    int? perPage,
    String? keyword,
  }) async {
    return await _remoteDataSource.getAllProduct(
      categoryId: categoryId,
      page: page,
      perPage: perPage,
      keyword: keyword,
    );
  }

  @override
  Future<Either<Failure, Product>> productDetail(int id) async {
    return await _remoteDataSource.productDetail(id);
  }
}
