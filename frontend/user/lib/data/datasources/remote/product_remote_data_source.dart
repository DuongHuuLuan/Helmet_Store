import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/product/product_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/product_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class ProductRemoteDataSource {
  final ProductService _service;

  ProductRemoteDataSource(this._service);

  Future<Either<Failure, List<Product>>> getAllProduct({
    int? categoryId,
    int? page,
    int? perPage,
    String? keyword,
  }) async {
    try {
      final response = categoryId != null
          ? await _service.getByCategory(
              categoryId,
              page: page,
              perPage: perPage,
            )
          : await _service.getAllProduct(
              page: page,
              perPage: perPage,
              keyword: keyword,
            );
      return Right(
        response.data.items.map(ProductMapper.fromModel).toList(),
      );
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, Product>> productDetail(int id) async {
    try {
      final response = await _service.productDetail(id);
      return Right(ProductMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }
}
