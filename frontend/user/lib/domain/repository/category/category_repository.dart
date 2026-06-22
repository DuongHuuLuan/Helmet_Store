import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/category/category.dart';
import 'package:dartz/dartz.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<Category>>> getAll();
  Future<Either<Failure, Category>> getById(int id);
  Future<Either<Failure, List<Category>>> getAllProudctByCategoryId(int categoryId);
}
