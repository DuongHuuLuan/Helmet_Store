import 'package:b2205946_duonghuuluan_luanvan/data/models/cart/cart_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'cart_service.g.dart';

@RestApi()
abstract class CartService {
  factory CartService(Dio dio, {String baseUrl}) = _CartService;

  @GET("/carts")
  Future<HttpResponse<CartModel>> getCart();

  @POST("/carts/cart-details")
  Future<HttpResponse<CartModel>> addCartDetail(@Body() Map<String, dynamic> data);

  @PUT("/carts/cart-details/{id}")
  Future<HttpResponse<CartModel>> updateCartDetail(
    @Path("id") int cartDetailId,
    @Query("new_quantity") int newQuantity,
  );

  @DELETE("/carts/cart-details/{id}")
  Future<HttpResponse<void>> deleteCartDetail(@Path("id") int cartDetailId);
}
