import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/evaluate/evaluate.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/evaluate/evaluate_reponsitory.dart';

class GetEvaluateByOrderUseCase {
  final EvaluateRepository _repo;
  GetEvaluateByOrderUseCase(this._repo);
  Future<Either<Failure, EvaluateItem?>> call(int orderId) => _repo.getEvaluateByOrder(orderId);
}
