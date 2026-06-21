import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/evaluate/evaluate.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/evaluate/evaluate_reponsitory.dart';

class GetEvaluateDetailUseCase {
  final EvaluateRepository _repo;
  GetEvaluateDetailUseCase(this._repo);
  Future<Either<Failure, EvaluateItem>> call(int evaluateId) => _repo.getEvaluateDetail(evaluateId);
}
