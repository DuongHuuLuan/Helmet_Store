import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/order/order_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/vnpay.dart';

class CreateVnpayPaymentUseCase {
  final OrderRepository _repo;
  CreateVnpayPaymentUseCase(this._repo);
  Future<Either<Failure, VnpayPaymentUrl>> call({required int orderId}) => _repo.createVnpayPayment(orderId: orderId);
}
