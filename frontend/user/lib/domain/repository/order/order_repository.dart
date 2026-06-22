import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/delivery_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/payment_method.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/vnpay.dart';
import 'package:dartz/dartz.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<OrderOut>>> getOrderHistory();
  Future<Either<Failure, OrderOut>> getOrderDetail(int orderId);
  Future<Either<Failure, OrderOut>> confirmDelivery(int orderId);
  Future<Either<Failure, Unit>> cancelOrder(int orderId);
  Future<Either<Failure, List<PaymentMethod>>> getPaymentMethods();
  Future<Either<Failure, List<DeliveryInfo>>> getDeliveryInfos();
  Future<Either<Failure, DeliveryInfo>> createDeliveryInfo({
    required String name,
    required String phone,
    required String address,
    required int? districtId,
    required String? wardCode,
    bool isDefault = false,
  });

  Future<Either<Failure, OrderOut>> createOrder(OrderCreate order);

  Future<Either<Failure, List<GhnProvince>>> getProvinces();
  Future<Either<Failure, List<GhnDistrict>>> getDistricts(int provinceId);
  Future<Either<Failure, List<GhnWard>>> getWards(int districtId);
  Future<Either<Failure, List<GhnServiceOption>>> getServices(int toDistrictId);

  Future<Either<Failure, GhnFee>> calculateFee({
    int? orderId,
    required int toDistrictId,
    required String toWardCode,
    required int serviceId,
    required int serviceTypeId,
    int? insuranceValue,
    required int weight,
  });

  Future<Either<Failure, GhnShipment>> createGhnOrder({
    required int orderId,
    required int toDistrictId,
    required String toWardCode,
    required int serviceId,
    required int serviceTypeId,
    required int weight,
    int? insuranceValue,
    String? note,
    String? requiredNote,
  });

  Future<Either<Failure, VnpayPaymentUrl>> createVnpayPayment({required int orderId});
}
