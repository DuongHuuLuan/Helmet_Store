import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/order/order_repository.dart';

class GetProvincesUseCase {
  final OrderRepository _repo;
  GetProvincesUseCase(this._repo);
  Future<Either<Failure, List<GhnProvince>>> call() => _repo.getProvinces();
}
