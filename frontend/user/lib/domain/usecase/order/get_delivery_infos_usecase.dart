import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/delivery_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/order/order_repository.dart';

class GetDeliveryInfosUseCase {
  final OrderRepository _repo;
  GetDeliveryInfosUseCase(this._repo);
  Future<Either<Failure, List<DeliveryInfo>>> call() => _repo.getDeliveryInfos();
}
