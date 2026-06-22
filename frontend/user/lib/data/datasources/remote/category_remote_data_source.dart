import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/category/category_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/category_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/category/category.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class CategoryRemoteDataSource {
  final CategoryService _service;

  CategoryRemoteDataSource(this._service);

  Future<Either<Failure, List<Category>>> getAll({
    int? page,
    int? perPage,
  }) async {
    try {
      final response = await _service.getAll(page: page, perPage: perPage);
      return Right(response.data.items.map(CategoryMapper.fromModel).toList());
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, Category>> getById(int id) async {
    try {
      final response = await _service.getById(id);
      return Right(CategoryMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }
}
