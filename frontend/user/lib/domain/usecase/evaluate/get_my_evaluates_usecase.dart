import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/evaluate/evaluate.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/evaluate/evaluate_reponsitory.dart';

class GetMyEvaluatesUseCase {
  final EvaluateRepository _repo;
  GetMyEvaluatesUseCase(this._repo);
  Future<Either<Failure, EvaluatePage>> call({int page = 1, int perPage = 8}) =>
      _repo.getMyEvaluates(page: page, perPage: perPage);
}
