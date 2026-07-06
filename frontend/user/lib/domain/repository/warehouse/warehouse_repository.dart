import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/warehouse/warehouse.dart';
import 'package:dartz/dartz.dart';

abstract class WarehouseRepository {
  Future<Either<Failure, WarehouseStock>> getTotalStock({
    required int productId,
    required int colorId,
    required int sizeId,
  });
}
