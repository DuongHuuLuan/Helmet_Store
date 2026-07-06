import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/order/order_repository.dart';

class GetDistrictsUseCase {
  final OrderRepository _repo;
  GetDistrictsUseCase(this._repo);
  Future<Either<Failure, List<GhnDistrict>>> call(int provinceId) => _repo.getDistricts(provinceId);
}
