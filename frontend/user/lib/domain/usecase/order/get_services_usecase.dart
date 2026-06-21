import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/order/order_repository.dart';

class GetServicesUseCase {
  final OrderRepository _repo;
  GetServicesUseCase(this._repo);
  Future<Either<Failure, List<GhnServiceOption>>> call(int toDistrictId) => _repo.getServices(toDistrictId);
}
