import 'dart:io';
import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/evaluate/evaluate_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/evaluate_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/evaluate/evaluate.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class EvaluateRemoteDataSource {
  final EvaluateService _service;

  EvaluateRemoteDataSource(this._service);

  Future<Either<Failure, EvaluatePage>> getMyEvaluates({int page = 1, int perPage = 8}) async {
    try {
      final response = await _service.getMyEvaluates(page: page, perPage: perPage);
      return Right(EvaluateMapper.pageFromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, ProductEvaluatePage>> getProductEvaluates({
    required int productId,
    int page = 1,
    int perPage = 3,
  }) async {
    try {
      final response = await _service.getProductEvaluates(
        productId,
        page: page,
        perPage: perPage,
      );
      return Right(EvaluateMapper.productPageFromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, EvaluateItem>> getEvaluateDetail(int evaluateId) async {
    try {
      final response = await _service.getEvaluateDetail(evaluateId);
      return Right(EvaluateMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, EvaluateItem?>> getEvaluateByOrder(int orderId) async {
    try {
      final response = await _service.getEvaluateByOrder(orderId);
      return Right<Failure, EvaluateItem?>(EvaluateMapper.fromModel(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const Right(null);
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, EvaluateItem>> createEvaluate({
    required int orderId,
    required int rate,
    String? content,
    List<String> imagePaths = const [],
  }) async {
    try {
      final images = imagePaths.isNotEmpty
          ? await Future.wait(
              imagePaths.map((p) => MultipartFile.fromFile(p, filename: p.split(Platform.pathSeparator).last)),
            )
          : null;
      final response = await _service.createEvaluate(
        orderId,
        rate,
        content: content?.trim().isEmpty == true ? null : content?.trim(),
        images: images,
      );
      return Right(EvaluateMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }
}
