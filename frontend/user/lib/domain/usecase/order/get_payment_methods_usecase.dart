import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/order/order_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/payment_method.dart';

class GetPaymentMethodsUseCase {
  final OrderRepository _repo;
  GetPaymentMethodsUseCase(this._repo);
  Future<Either<Failure, List<PaymentMethod>>> call() => _repo.getPaymentMethods();
}
