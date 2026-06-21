import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/order/cubit/order_state.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/delivery_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/payment_method.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/vnpay.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/calculate_fee_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/create_delivery_info_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/create_ghn_order_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/create_order_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/create_vnpay_payment_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_delivery_infos_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_districts_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_payment_methods_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_provinces_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_services_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_wards_usecase.dart';
import 'package:bloc/bloc.dart';

class OrderCubit extends Cubit<OrderState> {
  final GetPaymentMethodsUseCase _getPaymentMethods;
  final GetDeliveryInfosUseCase _getDeliveryInfos;
  final GetProvincesUseCase _getProvinces;
  final GetDistrictsUseCase _getDistricts;
  final GetWardsUseCase _getWards;
  final GetServicesUseCase _getServices;
  final CalculateFeeUseCase _calculateFee;
  final CreateOrderUseCase _createOrder;
  final CreateDeliveryInfoUseCase _createDeliveryInfo;
  final CreateGhnOrderUseCase _createGhnOrder;
  final CreateVnpayPaymentUseCase _createVnpayPayment;

  OrderCubit(
    this._getPaymentMethods,
    this._getDeliveryInfos,
    this._getProvinces,
    this._getDistricts,
    this._getWards,
    this._getServices,
    this._calculateFee,
    this._createOrder,
    this._createDeliveryInfo,
    this._createGhnOrder,
    this._createVnpayPayment,
  ) : super(const OrderState());

  int _shippingRequestToken = 0;
  int _feeRequestToken = 0;

  void setCartDetails(List<CartDetail> details) {
    emit(state.copyWith(cartDetails: details));
  }

  Future<void> loadInitialData() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final paymentsResult = await _getPaymentMethods();
    await paymentsResult.fold(
      (failure) async => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (payments) async {
        final deliveriesResult = await _getDeliveryInfos();
        await deliveriesResult.fold(
          (failure) async => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
          (deliveries) async {
            final provincesResult = await _getProvinces();
            await provincesResult.fold(
              (failure) async => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
              (provinces) async {
                emit(state.copyWith(
                  isLoading: false,
                  paymentMethods: payments,
                  selectedPayment: payments.isNotEmpty ? payments.first : null,
                  deliveries: deliveries,
                  selectedDelivery: deliveries.isNotEmpty ? deliveries.first : null,
                  useSavedAddress: deliveries.isNotEmpty,
                  provinces: provinces,
                ));
                if (deliveries.isNotEmpty) {
                  await _applyDeliveryShipping(deliveries.first);
                }
              },
            );
          },
        );
      },
    );
  }

  Future<void> selectProvince(GhnProvince? province) async {
    _shippingRequestToken++;
    _feeRequestToken++;
    emit(state.copyWith(
      errorMessage: null,
      selectedProvince: province,
      clearSelectedDistrict: true,
      clearSelectedWard: true,
      clearSelectedService: true,
      districts: const [],
      wards: const [],
      services: const [],
      clearFeeTotal: true,
    ));
    if (province == null) return;
    final result = await _getDistricts(province.provinceId);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (districts) => emit(state.copyWith(districts: districts)),
    );
  }

  Future<void> selectDistrict(GhnDistrict? district) async {
    _shippingRequestToken++;
    _feeRequestToken++;
    emit(state.copyWith(
      errorMessage: null,
      selectedDistrict: district,
      clearSelectedWard: true,
      clearSelectedService: true,
      wards: const [],
      services: const [],
      clearFeeTotal: true,
    ));
    if (district == null) return;
    final wardsResult = await _getWards(district.districtId);
    await wardsResult.fold(
      (failure) async => emit(state.copyWith(errorMessage: failure.message)),
      (wards) async {
        final servicesResult = await _getServices(district.districtId);
        servicesResult.fold(
          (failure) => emit(state.copyWith(errorMessage: failure.message)),
          (services) => emit(state.copyWith(
            wards: wards,
            services: services,
            selectedService: services.isNotEmpty ? services.first : null,
            errorMessage: services.isEmpty ? "Không lấy được dịch vụ GHN cho khu vực này." : null,
          )),
        );
      },
    );
  }

  void selectWard(GhnWard? ward) {
    _feeRequestToken++;
    emit(state.copyWith(errorMessage: null, selectedWard: ward, clearFeeTotal: true));
    _refreshFeeIfReady();
  }

  void selectService(GhnServiceOption? service) {
    _feeRequestToken++;
    emit(state.copyWith(errorMessage: null, selectedService: service, clearFeeTotal: true));
    _refreshFeeIfReady();
  }

  Future<void> selectDelivery(DeliveryInfo? delivery) async {
    _shippingRequestToken++;
    _feeRequestToken++;
    if (delivery == null) {
      emit(state.copyWith(
        clearSelectedDelivery: true,
        useSavedAddress: false,
        clearSelectedDistrict: true,
        clearSelectedWard: true,
        clearSelectedService: true,
        services: const [],
        clearFeeTotal: true,
        errorMessage: null,
      ));
      return;
    }
    emit(state.copyWith(selectedDelivery: delivery, useSavedAddress: true));
    await _applyDeliveryShipping(delivery);
  }

  Future<void> _applyDeliveryShipping(DeliveryInfo delivery) async {
    final requestToken = ++_shippingRequestToken;
    final districtId = delivery.districtId;
    final wardCode = delivery.wardCode?.trim() ?? "";

    emit(state.copyWith(
      clearSelectedDistrict: true,
      clearSelectedWard: true,
      clearSelectedService: true,
      services: const [],
      clearFeeTotal: true,
    ));

    if (districtId == null || districtId <= 0 || wardCode.isEmpty) {
      emit(state.copyWith(errorMessage: "Địa chỉ đã lưu thiếu district/ward. Vui lòng tạo lại địa chỉ."));
      return;
    }

    emit(state.copyWith(
      selectedDistrict: GhnDistrict(districtId: districtId, districtName: "Đã lưu"),
      selectedWard: GhnWard(wardCode: wardCode, wardName: "Đã lưu"),
    ));

    final result = await _getServices(districtId);
    result.fold(
      (failure) {
        if (requestToken != _shippingRequestToken) return;
        emit(state.copyWith(
          clearSelectedService: true,
          services: const [],
          clearFeeTotal: true,
          errorMessage: failure.message,
        ));
      },
      (services) {
        if (requestToken != _shippingRequestToken) return;
        emit(state.copyWith(
          services: services,
          selectedService: services.isNotEmpty ? services.first : null,
          errorMessage: services.isEmpty ? "Không lấy được dịch vụ GHN cho địa chỉ này." : null,
        ));
        if (services.isNotEmpty) _refreshFeeIfReady();
      },
    );
  }

  Future<void> calculateFee({int? insuranceValue}) async {
    final districtId = state.selectedDistrict?.districtId ?? 0;
    final wardCode = state.selectedWard?.wardCode.trim() ?? "";
    final serviceId = state.selectedService?.serviceId ?? 0;
    final serviceTypeId = state.selectedService?.serviceTypeId ?? 0;
    if (districtId <= 0 || wardCode.isEmpty || serviceId <= 0) {
      _feeRequestToken++;
      emit(state.copyWith(clearFeeTotal: true));
      return;
    }
    final requestToken = ++_feeRequestToken;
    const int defaultWeight = 1000;
    final result = await _calculateFee(
      toDistrictId: districtId,
      toWardCode: wardCode,
      serviceId: serviceId,
      serviceTypeId: serviceTypeId,
      insuranceValue: insuranceValue,
      weight: defaultWeight,
    );
    result.fold(
      (failure) {
        if (requestToken != _feeRequestToken) return;
        emit(state.copyWith(clearFeeTotal: true, errorMessage: failure.message));
      },
      (fee) {
        if (requestToken != _feeRequestToken) return;
        emit(state.copyWith(feeTotal: fee.total, errorMessage: null));
      },
    );
  }

  Future<VnpayPaymentUrl?> submitOrder({
    required String name,
    required String phone,
    required String address,
    String? note,
    String? requiredNote,
    List<int> discountIds = const [],
  }) async {
    if (state.selectedPayment == null ||
        state.selectedDistrict == null ||
        state.selectedWard == null ||
        state.selectedService == null) {
      emit(state.copyWith(errorMessage: "Vui lòng chọn đầy đủ địa chỉ và dịch vụ GHN"));
      return null;
    }
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final normalizedRequiredNote = _normalizeRequiredNote(requiredNote);

    // Step 1: delivery info
    DeliveryInfo deliveryInfo;
    if (state.useSavedAddress && state.selectedDelivery != null) {
      deliveryInfo = state.selectedDelivery!;
    } else {
      final deliveryResult = await _createDeliveryInfo(
        name: name,
        phone: phone,
        address: address,
        districtId: state.selectedDistrict!.districtId,
        wardCode: state.selectedWard!.wardCode,
      );
      final deliveryOrNull = deliveryResult.fold(
        (failure) {
          emit(state.copyWith(isLoading: false, errorMessage: failure.message));
          return null;
        },
        (info) => info,
      );
      if (deliveryOrNull == null) return null;
      deliveryInfo = deliveryOrNull;
    }

    // Step 2: create order
    final orderResult = await _createOrder(OrderCreate(
      deliveryInfoId: deliveryInfo.id,
      paymentMethodId: state.selectedPayment!.id,
      discountIds: discountIds,
      items: state.cartDetails
          .map((item) => OrderItemCreate(
                cartDetailId: item.id,
                productDetailId: item.productDetailId,
                quantity: item.quantity,
              ))
          .toList(),
    ));
    final orderOrNull = orderResult.fold(
      (failure) {
        emit(state.copyWith(isLoading: false, errorMessage: failure.message));
        return null;
      },
      (order) => order,
    );
    if (orderOrNull == null) return null;
    final order = orderOrNull;

    // Step 3: create GHN order
    final ghnResult = await _createGhnOrder(
      orderId: order.id,
      toDistrictId: state.selectedDistrict!.districtId,
      toWardCode: state.selectedWard!.wardCode,
      serviceId: state.selectedService!.serviceId,
      serviceTypeId: state.selectedService!.serviceTypeId,
      insuranceValue: null,
      note: note,
      requiredNote: normalizedRequiredNote,
      weight: 1000,
    );
    final ghnOrNull = ghnResult.fold(
      (failure) {
        emit(state.copyWith(isLoading: false, errorMessage: failure.message));
        return null;
      },
      (shipment) => shipment,
    );
    if (ghnOrNull == null) return null;

    // Step 4: handle payment
    final lowerName = state.selectedPayment!.name.toLowerCase();
    if (lowerName.contains("vnpay")) {
      final vnpayResult = await _createVnpayPayment(orderId: order.id);
      return vnpayResult.fold(
        (failure) {
          emit(state.copyWith(isLoading: false, errorMessage: failure.message));
          return null;
        },
        (url) {
          emit(state.copyWith(isLoading: false));
          return url;
        },
      );
    }

    emit(state.copyWith(isLoading: false, lastOrderId: order.id));
    return null;
  }

  String _normalizeRequiredNote(String? value) {
    const valid = {"KHONGCHOXEMHANG", "CHOXEMHANGKHONGTHU", "CHOTHUHANG"};
    if (value != null && valid.contains(value)) return value;
    return "KHONGCHOXEMHANG";
  }

  void selectPayment(PaymentMethod payment) {
    emit(state.copyWith(selectedPayment: payment));
  }

  Future<DeliveryInfo?> createDeliveryAddress({
    required String name,
    required String phone,
    required String address,
  }) async {
    if (state.selectedDistrict == null || state.selectedWard == null) {
      emit(state.copyWith(errorMessage: "Vui lòng chọn đầy đủ tỉnh/thành, quận/huyện và phường/xã"));
      return null;
    }
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await _createDeliveryInfo(
      name: name,
      phone: phone,
      address: address,
      districtId: state.selectedDistrict!.districtId,
      wardCode: state.selectedWard!.wardCode,
    );
    return result.fold(
      (failure) {
        emit(state.copyWith(isLoading: false, errorMessage: failure.message));
        return null;
      },
      (delivery) async {
        final deliveries = [delivery, ...state.deliveries.where((item) => item.id != delivery.id)];
        emit(state.copyWith(
          isLoading: false,
          deliveries: deliveries,
          selectedDelivery: delivery,
          useSavedAddress: true,
        ));
        await _applyDeliveryShipping(delivery);
        return delivery;
      },
    );
  }

  void _refreshFeeIfReady() {
    final districtId = state.selectedDistrict?.districtId ?? 0;
    final wardCode = state.selectedWard?.wardCode.trim() ?? "";
    final serviceId = state.selectedService?.serviceId ?? 0;
    if (districtId <= 0 || wardCode.isEmpty || serviceId <= 0) return;
    calculateFee(insuranceValue: _estimateInsuranceValue());
  }

  int _estimateInsuranceValue() {
    double total = 0;
    for (final item in state.cartDetails) {
      total += item.lineTotal;
    }
    return total <= 0 ? 0 : total.ceil();
  }
}
