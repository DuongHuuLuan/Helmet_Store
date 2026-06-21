import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/delivery_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/payment_method.dart';
import 'package:equatable/equatable.dart';

class OrderState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<CartDetail> cartDetails;
  final List<PaymentMethod> paymentMethods;
  final PaymentMethod? selectedPayment;
  final List<GhnProvince> provinces;
  final List<GhnDistrict> districts;
  final List<GhnWard> wards;
  final List<GhnServiceOption> services;
  final GhnProvince? selectedProvince;
  final GhnDistrict? selectedDistrict;
  final GhnWard? selectedWard;
  final GhnServiceOption? selectedService;
  final List<DeliveryInfo> deliveries;
  final DeliveryInfo? selectedDelivery;
  final bool useSavedAddress;
  final double? feeTotal;
  final int? lastOrderId;

  const OrderState({
    this.isLoading = false,
    this.errorMessage,
    this.cartDetails = const [],
    this.paymentMethods = const [],
    this.selectedPayment,
    this.provinces = const [],
    this.districts = const [],
    this.wards = const [],
    this.services = const [],
    this.selectedProvince,
    this.selectedDistrict,
    this.selectedWard,
    this.selectedService,
    this.deliveries = const [],
    this.selectedDelivery,
    this.useSavedAddress = true,
    this.feeTotal,
    this.lastOrderId,
  });

  OrderState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CartDetail>? cartDetails,
    List<PaymentMethod>? paymentMethods,
    PaymentMethod? selectedPayment,
    List<GhnProvince>? provinces,
    List<GhnDistrict>? districts,
    List<GhnWard>? wards,
    List<GhnServiceOption>? services,
    GhnProvince? selectedProvince,
    GhnDistrict? selectedDistrict,
    GhnWard? selectedWard,
    GhnServiceOption? selectedService,
    List<DeliveryInfo>? deliveries,
    DeliveryInfo? selectedDelivery,
    bool? useSavedAddress,
    double? feeTotal,
    int? lastOrderId,
    bool clearSelectedPayment = false,
    bool clearSelectedProvince = false,
    bool clearSelectedDistrict = false,
    bool clearSelectedWard = false,
    bool clearSelectedService = false,
    bool clearSelectedDelivery = false,
    bool clearFeeTotal = false,
  }) {
    return OrderState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      cartDetails: cartDetails ?? this.cartDetails,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      selectedPayment: clearSelectedPayment ? null : (selectedPayment ?? this.selectedPayment),
      provinces: provinces ?? this.provinces,
      districts: districts ?? this.districts,
      wards: wards ?? this.wards,
      services: services ?? this.services,
      selectedProvince: clearSelectedProvince ? null : (selectedProvince ?? this.selectedProvince),
      selectedDistrict: clearSelectedDistrict ? null : (selectedDistrict ?? this.selectedDistrict),
      selectedWard: clearSelectedWard ? null : (selectedWard ?? this.selectedWard),
      selectedService: clearSelectedService ? null : (selectedService ?? this.selectedService),
      deliveries: deliveries ?? this.deliveries,
      selectedDelivery: clearSelectedDelivery ? null : (selectedDelivery ?? this.selectedDelivery),
      useSavedAddress: useSavedAddress ?? this.useSavedAddress,
      feeTotal: clearFeeTotal ? null : (feeTotal ?? this.feeTotal),
      lastOrderId: lastOrderId ?? this.lastOrderId,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    errorMessage,
    cartDetails,
    paymentMethods,
    selectedPayment,
    provinces,
    districts,
    wards,
    services,
    selectedProvince,
    selectedDistrict,
    selectedWard,
    selectedService,
    deliveries,
    selectedDelivery,
    useSavedAddress,
    feeTotal,
    lastOrderId,
  ];
}
