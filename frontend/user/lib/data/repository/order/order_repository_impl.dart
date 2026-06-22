import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/order_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/delivery_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/payment_method.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/vnpay.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/order/order_repository.dart';
import 'package:dartz/dartz.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;

  OrderRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<OrderOut>>> getOrderHistory() async {
    return await _remoteDataSource.getOrderHistory();
  }

  @override
  Future<Either<Failure, OrderOut>> getOrderDetail(int orderId) async {
    return await _remoteDataSource.getOrderDetail(orderId);
  }

  @override
  Future<Either<Failure, OrderOut>> confirmDelivery(int orderId) async {
    final result = await _remoteDataSource.confirmDelivery(orderId);
    return result.fold(
      (failure) => Left(failure),
      (_) => _remoteDataSource.getOrderDetail(orderId),
    );
  }

  @override
  Future<Either<Failure, Unit>> cancelOrder(int orderId) async {
    return await _remoteDataSource.cancelOrder(orderId);
  }

  @override
  Future<Either<Failure, List<PaymentMethod>>> getPaymentMethods() async {
    return await _remoteDataSource.getPaymentMethods();
  }

  @override
  Future<Either<Failure, List<DeliveryInfo>>> getDeliveryInfos() async {
    return await _remoteDataSource.getDeliveryInfos();
  }

  @override
  Future<Either<Failure, DeliveryInfo>> createDeliveryInfo({
    required String name,
    required String phone,
    required String address,
    required int? districtId,
    required String? wardCode,
    bool isDefault = false,
  }) async {
    return await _remoteDataSource.createDeliveryInfo({
      "name": name,
      "phone": phone,
      "address": address,
      "district_id": districtId,
      "ward_code": wardCode,
      "default": isDefault,
    });
  }

  @override
  Future<Either<Failure, OrderOut>> createOrder(OrderCreate order) async {
    return await _remoteDataSource.createOrder({
      "delivery_info_id": order.deliveryInfoId,
      "payment_method_id": order.paymentMethodId,
      "discount_ids": order.discountIds,
      "order_items": order.items
          .map((item) => {
                "cart_detail_id": item.cartDetailId,
                "product_detail_id": item.productDetailId,
                "quantity": item.quantity,
              })
          .toList(),
    });
  }

  @override
  Future<Either<Failure, List<GhnProvince>>> getProvinces() async {
    return await _remoteDataSource.getProvinces();
  }

  @override
  Future<Either<Failure, List<GhnDistrict>>> getDistricts(int provinceId) async {
    return await _remoteDataSource.getDistricts(provinceId);
  }

  @override
  Future<Either<Failure, List<GhnWard>>> getWards(int districtId) async {
    return await _remoteDataSource.getWards(districtId);
  }

  @override
  Future<Either<Failure, List<GhnServiceOption>>> getServices(int toDistrictId) async {
    return await _remoteDataSource.getServices(toDistrictId);
  }

  @override
  Future<Either<Failure, GhnFee>> calculateFee({
    int? orderId,
    required int toDistrictId,
    required String toWardCode,
    required int serviceId,
    required int serviceTypeId,
    int? insuranceValue,
    required int weight,
  }) async {
    final payload = <String, dynamic>{
      "to_district_id": toDistrictId,
      "to_ward_code": toWardCode.trim(),
      "insurance_value": insuranceValue,
      "weight": weight,
      "Weight": weight,
    };
    if (serviceId > 0) payload["service_id"] = serviceId;
    if (serviceTypeId > 0) payload["service_type_id"] = serviceTypeId;
    if (orderId != null) payload["order_id"] = orderId;
    return await _remoteDataSource.calculateFee(payload);
  }

  @override
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
  }) async {
    final payload = <String, dynamic>{
      "order_id": orderId,
      "to_district_id": toDistrictId,
      "to_ward_code": toWardCode.trim(),
      "insurance_value": insuranceValue,
      "weight": weight,
      "Weight": weight,
      "note": note,
      "required_note": requiredNote,
    };
    if (serviceId > 0) payload["service_id"] = serviceId;
    if (serviceTypeId > 0) payload["service_type_id"] = serviceTypeId;
    return await _remoteDataSource.createGhnOrder(payload);
  }

  @override
  Future<Either<Failure, VnpayPaymentUrl>> createVnpayPayment({required int orderId}) async {
    return await _remoteDataSource.createVnpayPayment({"order_id": orderId});
  }
}
