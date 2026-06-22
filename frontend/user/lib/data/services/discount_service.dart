import 'package:b2205946_duonghuuluan_luanvan/data/models/discount/discount_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'discount_service.g.dart';

@RestApi()
abstract class DiscountService {
  factory DiscountService(Dio dio, {String baseUrl}) = _DiscountService;

  @GET("/discounts/discount-cart")
  Future<HttpResponse<List<DiscountModel>>> getDiscountsForCart(
    @Query("category_ids") List<int> categoryIds,
  );

  @GET("/discounts/my")
  Future<HttpResponse<List<DiscountModel>>> getMyDiscounts({
    @Query("status") String? status,
  });

  @POST("/discounts/add-by-code")
  Future<HttpResponse<DiscountModel>> addDiscountByCode(@Body() Map<String, dynamic> data);
}
