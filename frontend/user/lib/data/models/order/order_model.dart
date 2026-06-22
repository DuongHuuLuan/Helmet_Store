import 'package:json_annotation/json_annotation.dart';
import 'order_detail_model.dart';
import 'delivery_info_model.dart';
import 'payment_method_model.dart';

part 'order_model.g.dart';

@JsonSerializable(explicitToJson: true)
class OrderModel {
  final int id;
  final String? status;
  @JsonKey(name: 'payment_status')
  final String? paymentStatus;
  @JsonKey(name: 'refund_support_status')
  final String? refundSupportStatus;
  @JsonKey(name: 'rejection_reason')
  final String? rejectionReason;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'shipping_fee')
  final double? shippingFee;
  @JsonKey(name: 'order_details')
  final List<OrderDetailModel>? orderDetails;
  @JsonKey(name: 'discount_code')
  final String? discountCode;
  @JsonKey(name: 'delivery_info')
  final DeliveryInfoModel? deliveryInfo;
  @JsonKey(name: 'payment_method')
  final PaymentMethodModel? paymentMethod;

  OrderModel({
    required this.id,
    this.status,
    this.paymentStatus,
    this.refundSupportStatus,
    this.rejectionReason,
    this.createdAt,
    this.shippingFee,
    this.orderDetails,
    this.discountCode,
    this.deliveryInfo,
    this.paymentMethod,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);
}
