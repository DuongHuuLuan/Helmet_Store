import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/warehouse_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/warehouse/warehouse.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/warehouse/warehouse_repository.dart';
import 'package:dartz/dartz.dart';

class WarehouseRepositoryImpl implements WarehouseRepository {
  final WarehouseRemoteDataSource _remoteDataSource;

  WarehouseRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, WarehouseStock>> getTotalStock({
    required int productId,
    required int colorId,
    required int sizeId,
  }) async {
    return await _remoteDataSource.getTotalStock(
      productId: productId,
      colorId: colorId,
      sizeId: sizeId,
    );
  }
}
