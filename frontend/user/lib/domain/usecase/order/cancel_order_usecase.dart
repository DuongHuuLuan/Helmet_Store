import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/order/order_repository.dart';

class CancelOrderUseCase {
  final OrderRepository _repo;
  CancelOrderUseCase(this._repo);
  Future<Either<Failure, Unit>> call(int orderId) => _repo.cancelOrder(orderId);
}
