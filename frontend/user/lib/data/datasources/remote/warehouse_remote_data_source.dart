import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/warehouse_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/warehouse/warehouse.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class WarehouseRemoteDataSource {
  final WarehouseService _service;

  WarehouseRemoteDataSource(this._service);

  Future<Either<Failure, WarehouseStock>> getTotalStock({
    required int productId,
    required int colorId,
    required int sizeId,
  }) async {
    try {
      final response = await _service.getTotalStock(productId, colorId, sizeId);
      final model = response.data;
      return Right(
        WarehouseStock(
          productId: model.productId,
          colorId: model.colorId,
          sizeId: model.sizeId,
          quantity: model.quantity,
        ),
      );
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    } catch (e) {
      return Left(Failure.fromError(e));
    }
  }
}
