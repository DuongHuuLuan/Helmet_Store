import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/order/order_repository.dart';

class CreateOrderUseCase {
  final OrderRepository _repo;
  CreateOrderUseCase(this._repo);
  Future<Either<Failure, OrderOut>> call(OrderCreate order) => _repo.createOrder(order);
}
