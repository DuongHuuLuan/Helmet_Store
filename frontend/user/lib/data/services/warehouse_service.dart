import 'package:b2205946_duonghuuluan_luanvan/data/models/warehouse/warehouse_stock_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'warehouse_service.g.dart';

@RestApi()
abstract class WarehouseService {
  factory WarehouseService(Dio dio, {String baseUrl}) = _WarehouseService;

  @GET("/warehouses/product-quantity")
  Future<HttpResponse<WarehouseStockModel>> getTotalStock(
    @Query("product_id") int productId,
    @Query("color_id") int colorId,
    @Query("size_id") int sizeId,
  );
}
