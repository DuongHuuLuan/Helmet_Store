import 'package:json_annotation/json_annotation.dart';

part 'ghn_models.g.dart';

@JsonSerializable()
class GhnProvinceModel {
  @JsonKey(name: 'ProvinceID')
  final int provinceId;
  @JsonKey(name: 'ProvinceName')
  final String provinceName;

  GhnProvinceModel({required this.provinceId, required this.provinceName});

  factory GhnProvinceModel.fromJson(Map<String, dynamic> json) =>
      _$GhnProvinceModelFromJson(json);

  Map<String, dynamic> toJson() => _$GhnProvinceModelToJson(this);
}

@JsonSerializable()
class GhnDistrictModel {
  @JsonKey(name: 'DistrictID')
  final int districtId;
  @JsonKey(name: 'DistrictName')
  final String districtName;

  GhnDistrictModel({required this.districtId, required this.districtName});

  factory GhnDistrictModel.fromJson(Map<String, dynamic> json) =>
      _$GhnDistrictModelFromJson(json);

  Map<String, dynamic> toJson() => _$GhnDistrictModelToJson(this);
}

@JsonSerializable()
class GhnWardModel {
  @JsonKey(name: 'WardCode')
  final String wardCode;
  @JsonKey(name: 'WardName')
  final String wardName;

  GhnWardModel({required this.wardCode, required this.wardName});

  factory GhnWardModel.fromJson(Map<String, dynamic> json) =>
      _$GhnWardModelFromJson(json);

  Map<String, dynamic> toJson() => _$GhnWardModelToJson(this);
}

@JsonSerializable()
class GhnServiceOptionModel {
  @JsonKey(name: 'service_id')
  final int serviceId;
  @JsonKey(name: 'service_type_id')
  final int serviceTypeId;
  @JsonKey(name: 'short_name')
  final String shortName;

  GhnServiceOptionModel({
    required this.serviceId,
    required this.serviceTypeId,
    required this.shortName,
  });

  factory GhnServiceOptionModel.fromJson(Map<String, dynamic> json) =>
      _$GhnServiceOptionModelFromJson(json);

  Map<String, dynamic> toJson() => _$GhnServiceOptionModelToJson(this);
}

@JsonSerializable()
class GhnFeeModel {
  final double total;
  @JsonKey(name: 'service_fee')
  final double? serviceFee;
  @JsonKey(name: 'insurance_fee')
  final double? insuranceFee;

  GhnFeeModel({required this.total, this.serviceFee, this.insuranceFee});

  factory GhnFeeModel.fromJson(Map<String, dynamic> json) =>
      _$GhnFeeModelFromJson(json);

  Map<String, dynamic> toJson() => _$GhnFeeModelToJson(this);
}

@JsonSerializable()
class GhnShipmentModel {
  final int id;
  @JsonKey(name: 'order_id')
  final int orderId;
  @JsonKey(name: 'ghn_order_code')
  final String? ghnOrderCode;
  final String? status;
  @JsonKey(name: 'shipping_fee')
  final double? shippingFee;

  GhnShipmentModel({
    required this.id,
    required this.orderId,
    this.ghnOrderCode,
    this.status,
    this.shippingFee,
  });

  factory GhnShipmentModel.fromJson(Map<String, dynamic> json) =>
      _$GhnShipmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$GhnShipmentModelToJson(this);
}
