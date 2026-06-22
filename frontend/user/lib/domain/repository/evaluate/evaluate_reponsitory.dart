import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/evaluate/evaluate.dart';
import 'package:dartz/dartz.dart';

abstract class EvaluateRepository {
  Future<Either<Failure, EvaluatePage>> getMyEvaluates({int page = 1, int perPage = 8});
  Future<Either<Failure, ProductEvaluatePage>> getProductEvaluates({
    required int productId,
    int page = 1,
    int perPage = 3,
  });
  Future<Either<Failure, EvaluateItem>> getEvaluateDetail(int evaluateId);
  Future<Either<Failure, EvaluateItem?>> getEvaluateByOrder(int orderId);
  Future<Either<Failure, EvaluateItem>> createEvaluate({
    required int orderId,
    required int rate,
    String? content,
    List<String> imagePaths = const [],
  });
}
