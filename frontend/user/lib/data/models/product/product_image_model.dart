import 'package:json_annotation/json_annotation.dart';

part 'product_image_model.g.dart';

@JsonSerializable()
class ProductImageModel {
  final int id;
  final String url;
  @JsonKey(name: 'public_id')
  final String? publicId;
  @JsonKey(name: 'color_id')
  final int? colorId;
  @JsonKey(name: 'view_image_key')
  final String? viewImageKey;

  ProductImageModel({
    required this.id,
    required this.url,
    this.publicId,
    this.colorId,
    this.viewImageKey,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) =>
      _$ProductImageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductImageModelToJson(this);
}
