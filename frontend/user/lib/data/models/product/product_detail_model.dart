import 'package:json_annotation/json_annotation.dart';

part 'product_detail_model.g.dart';

@JsonSerializable()
class ProductColorModel {
  final int id;
  final String name;
  final String hexcode;

  ProductColorModel({
    required this.id,
    required this.name,
    required this.hexcode,
  });

  factory ProductColorModel.fromJson(Map<String, dynamic> json) =>
      _$ProductColorModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductColorModelToJson(this);
}

@JsonSerializable()
class ProductSizeModel {
  final int id;
  final String size;

  ProductSizeModel({
    required this.id,
    required this.size,
  });

  factory ProductSizeModel.fromJson(Map<String, dynamic> json) =>
      _$ProductSizeModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductSizeModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductDetailModel {
  final int id;
  final ProductColorModel color;
  final ProductSizeModel size;
  final double price;
  @JsonKey(name: 'is_active')
  final bool isActive;

  ProductDetailModel({
    required this.id,
    required this.color,
    required this.size,
    required this.price,
    required this.isActive,
  });

  int get colorId => color.id;
  String get colorName => color.name;
  String get colorHex => color.hexcode;
  int get sizeId => size.id;
  String get sizeLabel => size.size;

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) =>
      _$ProductDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductDetailModelToJson(this);
}
