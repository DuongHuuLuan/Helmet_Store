import 'package:json_annotation/json_annotation.dart';

part 'delivery_info_model.g.dart';

@JsonSerializable()
class DeliveryInfoModel {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String name;
  final String address;
  final String phone;
  @JsonKey(name: 'district_id')
  final int? districtId;
  @JsonKey(name: 'ward_code')
  final String? wardCode;

  DeliveryInfoModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.phone,
    this.districtId,
    this.wardCode,
  });

  factory DeliveryInfoModel.fromJson(Map<String, dynamic> json) =>
      _$DeliveryInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryInfoModelToJson(this);
}
