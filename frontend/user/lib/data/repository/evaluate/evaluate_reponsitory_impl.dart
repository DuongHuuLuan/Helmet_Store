import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/evaluate_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/evaluate/evaluate.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/evaluate/evaluate_reponsitory.dart';
import 'package:dartz/dartz.dart';

class EvaluateRepositoryImpl implements EvaluateRepository {
  final EvaluateRemoteDataSource _remoteDataSource;

  EvaluateRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, EvaluatePage>> getMyEvaluates({int page = 1, int perPage = 8}) async {
    return await _remoteDataSource.getMyEvaluates(page: page, perPage: perPage);
  }

  @override
  Future<Either<Failure, ProductEvaluatePage>> getProductEvaluates({
    required int productId,
    int page = 1,
    int perPage = 3,
  }) async {
    return await _remoteDataSource.getProductEvaluates(
      productId: productId,
      page: page,
      perPage: perPage,
    );
  }

  @override
  Future<Either<Failure, EvaluateItem>> getEvaluateDetail(int evaluateId) async {
    return await _remoteDataSource.getEvaluateDetail(evaluateId);
  }

  @override
  Future<Either<Failure, EvaluateItem?>> getEvaluateByOrder(int orderId) async {
    return await _remoteDataSource.getEvaluateByOrder(orderId);
  }

  @override
  Future<Either<Failure, EvaluateItem>> createEvaluate({
    required int orderId,
    required int rate,
    String? content,
    List<String> imagePaths = const [],
  }) async {
    return await _remoteDataSource.createEvaluate(
      orderId: orderId,
      rate: rate,
      content: content,
      imagePaths: imagePaths,
    );
  }
}
