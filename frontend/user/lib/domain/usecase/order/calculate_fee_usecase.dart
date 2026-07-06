import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/order/order_repository.dart';

class CalculateFeeUseCase {
  final OrderRepository _repo;
  CalculateFeeUseCase(this._repo);
  Future<Either<Failure, GhnFee>> call({int? orderId, required int toDistrictId, required String toWardCode, required int serviceId, required int serviceTypeId, int? insuranceValue, required int weight}) =>
      _repo.calculateFee(orderId: orderId, toDistrictId: toDistrictId, toWardCode: toWardCode, serviceId: serviceId, serviceTypeId: serviceTypeId, insuranceValue: insuranceValue, weight: weight);
}
