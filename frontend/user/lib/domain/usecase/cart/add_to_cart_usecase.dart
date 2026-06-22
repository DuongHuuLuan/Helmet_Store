import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/cart/cart_repository.dart';

class AddToCartUseCase {
  final CartRepository _repo;
  AddToCartUseCase(this._repo);
  Future<Either<Failure, Cart>> call({required int productDetailId, int quantity = 1}) =>
      _repo.addToCart(productDetailId: productDetailId, quantity: quantity);
}
