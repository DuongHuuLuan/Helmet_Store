import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/order/order_repository.dart';

class CreateGhnOrderUseCase {
  final OrderRepository _repo;
  CreateGhnOrderUseCase(this._repo);
  Future<Either<Failure, GhnShipment>> call({required int orderId, required int toDistrictId, required String toWardCode, required int serviceId, required int serviceTypeId, required int weight, int? insuranceValue, String? note, String? requiredNote}) =>
      _repo.createGhnOrder(orderId: orderId, toDistrictId: toDistrictId, toWardCode: toWardCode, serviceId: serviceId, serviceTypeId: serviceTypeId, weight: weight, insuranceValue: insuranceValue, note: note, requiredNote: requiredNote);
}
