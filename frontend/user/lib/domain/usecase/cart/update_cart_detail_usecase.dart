import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/cart/cart_repository.dart';

class UpdateCartDetailUseCase {
  final CartRepository _repo;
  UpdateCartDetailUseCase(this._repo);
  Future<Either<Failure, Cart>> call({required int cartDetailId, required int newQuantity}) =>
      _repo.updateCartDetail(cartDetailId: cartDetailId, newQuantity: newQuantity);
}
