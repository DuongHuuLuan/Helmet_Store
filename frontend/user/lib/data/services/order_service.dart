import 'package:b2205946_duonghuuluan_luanvan/data/models/order/order_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/order/delivery_info_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/order/payment_method_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/order/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/order/vnpay_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'order_service.g.dart';

@RestApi()
abstract class OrderService {
  factory OrderService(Dio dio, {String baseUrl}) = _OrderService;

  @GET("/orders/history")
  Future<HttpResponse<List<OrderModel>>> getOrderHistory();

  @GET("/orders/{id}")
  Future<HttpResponse<OrderModel>> getOrderDetail(@Path("id") int orderId);

  @POST("/orders/{id}/confirm-delivery")
  Future<HttpResponse<void>> confirmDelivery(@Path("id") int orderId);

  @POST("/orders/{id}/cancel")
  Future<HttpResponse<void>> cancelOrder(@Path("id") int orderId);

  @GET("/payment/")
  Future<HttpResponse<List<PaymentMethodModel>>> getPaymentMethods();

  @POST("/delivery/")
  Future<HttpResponse<DeliveryInfoModel>> createDeliveryInfo(@Body() Map<String, dynamic> data);

  @GET("/delivery/")
  Future<HttpResponse<List<DeliveryInfoModel>>> getDeliveryInfos();

  @POST("/orders/")
  Future<HttpResponse<OrderModel>> createOrder(@Body() Map<String, dynamic> data);

  @GET("/ghn/provinces")
  Future<HttpResponse<List<GhnProvinceModel>>> getProvinces();

  @GET("/ghn/districts/{id}")
  Future<HttpResponse<List<GhnDistrictModel>>> getDistricts(@Path("id") int provinceId);

  @GET("/ghn/wards/{id}")
  Future<HttpResponse<List<GhnWardModel>>> getWards(@Path("id") int districtId);

  @GET("/ghn/services")
  Future<HttpResponse<List<GhnServiceOptionModel>>> getServices(
    @Query("to_district_id") int toDistrictId,
  );

  @POST("/ghn/fee")
  Future<HttpResponse<GhnFeeModel>> calculateFee(@Body() Map<String, dynamic> data);

  @POST("/ghn/create-order")
  Future<HttpResponse<GhnShipmentModel>> createGhnOrder(@Body() Map<String, dynamic> data);

  @POST("/vnpay/create-payment")
  Future<HttpResponse<VnpayPaymentUrlModel>> createVnpayPayment(@Body() Map<String, dynamic> data);
}
