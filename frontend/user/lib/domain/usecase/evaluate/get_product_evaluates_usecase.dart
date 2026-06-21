import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/evaluate/evaluate.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/evaluate/evaluate_reponsitory.dart';

class GetProductEvaluatesUseCase {
  final EvaluateRepository _repo;
  GetProductEvaluatesUseCase(this._repo);
  Future<Either<Failure, ProductEvaluatePage>> call({required int productId, int page = 1, int perPage = 3}) =>
      _repo.getProductEvaluates(productId: productId, page: page, perPage: perPage);
}
