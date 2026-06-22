import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/cart/cart_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/cart_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class CartRemoteDataSource {
  final CartService _service;

  CartRemoteDataSource(this._service);

  Future<Either<Failure, Cart>> getCart() async {
    try {
      final response = await _service.getCart();
      return Right(CartMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, Cart>> addCartDetail({
    required int productDetailId,
    int quantity = 1,
  }) async {
    try {
      final response = await _service.addCartDetail({
        "product_detail_id": productDetailId,
        "quantity": quantity,
      });
      return Right(CartMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, Cart>> updateCartDetail({
    required int cartDetailId,
    required int newQuantity,
  }) async {
    try {
      final response = await _service.updateCartDetail(cartDetailId, newQuantity);
      return Right(CartMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, Unit>> deleteCartDetail({required int cartDetailId}) async {
    try {
      await _service.deleteCartDetail(cartDetailId);
      return Right(unit);
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }
}
