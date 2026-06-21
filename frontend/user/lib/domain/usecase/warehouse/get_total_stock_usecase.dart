import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/warehouse/warehouse.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/warehouse/warehouse_repository.dart';
import 'package:dartz/dartz.dart';

class GetTotalStockUseCase {
  final WarehouseRepository _repo;
  GetTotalStockUseCase(this._repo);
  Future<Either<Failure, WarehouseStock>> call({required int productId, required int colorId, required int sizeId}) =>
      _repo.getTotalStock(productId: productId, colorId: colorId, sizeId: sizeId);
}
