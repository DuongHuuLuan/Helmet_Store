import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';
import 'package:dartz/dartz.dart';

abstract class CartRepository {
  Future<Either<Failure, Cart>> getCart();
  Future<Either<Failure, Cart>> addToCart({required int productDetailId, required int quantity});
  Future<Either<Failure, Cart>> updateCartDetail({
    required int cartDetailId,
    required int newQuantity,
  });
  Future<Either<Failure, Unit>> deleteCartDetail({required int cartDetailId});
}
