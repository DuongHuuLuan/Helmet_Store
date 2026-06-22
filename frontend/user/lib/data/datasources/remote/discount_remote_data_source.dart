import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/discount/discount_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/discount_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/discount/discount.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class DiscountRemoteDataSource {
  final DiscountService _service;

  DiscountRemoteDataSource(this._service);

  Future<Either<Failure, List<Discount>>> getDiscountsForCart({required List<int> categoryIds}) async {
    try {
      final response = await _service.getDiscountsForCart(categoryIds);
      return Right(response.data.map(DiscountMapper.fromModel).toList());
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, List<Discount>>> getMyDiscounts({String? status}) async {
    try {
      final response = await _service.getMyDiscounts(status: status);
      return Right(response.data.map(DiscountMapper.fromModel).toList());
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, Discount>> addDiscountByCode(String code) async {
    try {
      final response = await _service.addDiscountByCode({"code": code});
      return Right(DiscountMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }
}
