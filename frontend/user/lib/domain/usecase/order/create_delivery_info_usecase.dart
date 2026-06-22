import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/delivery_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/order/order_repository.dart';

class CreateDeliveryInfoUseCase {
  final OrderRepository _repo;
  CreateDeliveryInfoUseCase(this._repo);
  Future<Either<Failure, DeliveryInfo>> call({required String name, required String phone, required String address, required int? districtId, required String? wardCode, bool isDefault = false}) =>
      _repo.createDeliveryInfo(name: name, phone: phone, address: address, districtId: districtId, wardCode: wardCode, isDefault: isDefault);
}
