import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/category/category.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/category/category_repository.dart';

class GetCategoriesUseCase {
  final CategoryRepository _repo;
  GetCategoriesUseCase(this._repo);
  Future<Either<Failure, List<Category>>> call() => _repo.getAll();
}
