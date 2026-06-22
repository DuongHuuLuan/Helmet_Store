import 'package:json_annotation/json_annotation.dart';

part 'vnpay_model.g.dart';

@JsonSerializable()
class VnpayPaymentUrlModel {
  @JsonKey(name: 'payment_url')
  final String paymentUrl;

  VnpayPaymentUrlModel({required this.paymentUrl});

  factory VnpayPaymentUrlModel.fromJson(Map<String, dynamic> json) =>
      _$VnpayPaymentUrlModelFromJson(json);

  Map<String, dynamic> toJson() => _$VnpayPaymentUrlModelToJson(this);
}
