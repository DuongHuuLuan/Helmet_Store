import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/category_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/category/category.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/category/category_repository.dart';
import 'package:dartz/dartz.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource _remoteDataSource;

  CategoryRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Category>>> getAll() async {
    return await _remoteDataSource.getAll();
  }

  @override
  Future<Either<Failure, Category>> getById(int id) async {
    return await _remoteDataSource.getById(id);
  }

  @override
  Future<Either<Failure, List<Category>>> getAllProudctByCategoryId(int categoryId) async {
    throw UnimplementedError("Deprecated - use ProductService instead");
  }
}
