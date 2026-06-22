import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/cart_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/cart/cart_repository.dart';
import 'package:dartz/dartz.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource _remoteDataSource;

  CartRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, Cart>> getCart() async {
    return await _remoteDataSource.getCart();
  }

  @override
  Future<Either<Failure, Cart>> addToCart({
    required int productDetailId,
    required int quantity,
  }) async {
    return await _remoteDataSource.addCartDetail(productDetailId: productDetailId, quantity: quantity);
  }

  @override
  Future<Either<Failure, Cart>> updateCartDetail({
    required int cartDetailId,
    required int newQuantity,
  }) async {
    return await _remoteDataSource.updateCartDetail(cartDetailId: cartDetailId, newQuantity: newQuantity);
  }

  @override
  Future<Either<Failure, Unit>> deleteCartDetail({required int cartDetailId}) async {
    return await _remoteDataSource.deleteCartDetail(cartDetailId: cartDetailId);
  }
}
