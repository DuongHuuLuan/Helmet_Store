import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/order/delivery_info_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/order/ghn_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/order/order_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/order/payment_method_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/order/vnpay_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/order_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/delivery_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/payment_method.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/vnpay.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class OrderRemoteDataSource {
  final OrderService _service;

  OrderRemoteDataSource(this._service);

  Future<Either<Failure, List<OrderOut>>> getOrderHistory() async {
    try {
      final response = await _service.getOrderHistory();
      return Right(response.data.map(OrderMapper.fromModel).toList());
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, OrderOut>> getOrderDetail(int orderId) async {
    try {
      final response = await _service.getOrderDetail(orderId);
      return Right(OrderMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, Unit>> confirmDelivery(int orderId) async {
    try {
      await _service.confirmDelivery(orderId);
      return Right(unit);
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, Unit>> cancelOrder(int orderId) async {
    try {
      await _service.cancelOrder(orderId);
      return Right(unit);
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, List<PaymentMethod>>> getPaymentMethods() async {
    try {
      final response = await _service.getPaymentMethods();
      return Right(response.data.map(PaymentMethodMapper.fromModel).toList());
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, List<DeliveryInfo>>> getDeliveryInfos() async {
    try {
      final response = await _service.getDeliveryInfos();
      return Right(response.data.map(DeliveryInfoMapper.fromModel).toList());
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, DeliveryInfo>> createDeliveryInfo(Map<String, dynamic> data) async {
    try {
      final response = await _service.createDeliveryInfo(data);
      return Right(DeliveryInfoMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, OrderOut>> createOrder(Map<String, dynamic> data) async {
    try {
      final response = await _service.createOrder(data);
      return Right(OrderMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, List<GhnProvince>>> getProvinces() async {
    try {
      final response = await _service.getProvinces();
      return Right(GhnMapper.provinces(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, List<GhnDistrict>>> getDistricts(int provinceId) async {
    try {
      final response = await _service.getDistricts(provinceId);
      return Right(GhnMapper.districts(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, List<GhnWard>>> getWards(int districtId) async {
    try {
      final response = await _service.getWards(districtId);
      return Right(GhnMapper.wards(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, List<GhnServiceOption>>> getServices(int toDistrictId) async {
    try {
      final response = await _service.getServices(toDistrictId);
      return Right(GhnMapper.services(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, GhnFee>> calculateFee(Map<String, dynamic> data) async {
    try {
      final response = await _service.calculateFee(data);
      return Right(GhnMapper.fee(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, GhnShipment>> createGhnOrder(Map<String, dynamic> data) async {
    try {
      final response = await _service.createGhnOrder(data);
      return Right(GhnMapper.shipment(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, VnpayPaymentUrl>> createVnpayPayment(Map<String, dynamic> data) async {
    try {
      final response = await _service.createVnpayPayment(data);
      return Right(VnpayMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }
}
