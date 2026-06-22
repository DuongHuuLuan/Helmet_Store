import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/cart/cart_repository.dart';

class RemoveFromCartUseCase {
  final CartRepository _repo;
  RemoveFromCartUseCase(this._repo);
  Future<Either<Failure, Unit>> call({required int cartDetailId}) =>
      _repo.deleteCartDetail(cartDetailId: cartDetailId);
}
