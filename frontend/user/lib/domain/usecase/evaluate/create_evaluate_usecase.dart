import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/evaluate/evaluate.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/evaluate/evaluate_reponsitory.dart';

class CreateEvaluateUseCase {
  final EvaluateRepository _repo;
  CreateEvaluateUseCase(this._repo);
  Future<Either<Failure, EvaluateItem>> call({required int orderId, required int rate, String? content, List<String> imagePaths = const []}) =>
      _repo.createEvaluate(orderId: orderId, rate: rate, content: content, imagePaths: imagePaths);
}
