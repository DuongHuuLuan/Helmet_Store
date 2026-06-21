import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/cart/cart_repository.dart';

class GetCartUseCase {
  final CartRepository _repo;
  GetCartUseCase(this._repo);
  Future<Either<Failure, Cart>> call() => _repo.getCart();
}
