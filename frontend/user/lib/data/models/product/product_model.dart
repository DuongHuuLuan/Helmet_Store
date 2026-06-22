import 'package:json_annotation/json_annotation.dart';
import 'product_detail_model.dart';
import 'product_image_model.dart';

part 'product_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProductModel {
  final int id;
  final String name;
  final String? description;
  final String? unit;
  @JsonKey(name: 'category_id')
  final int categoryId;
  @JsonKey(name: 'product_images')
  final List<ProductImageModel>? productImages;
  @JsonKey(name: 'design_views')
  final List<ProductImageModel>? designViews;
  @JsonKey(name: 'product_details')
  final List<ProductDetailModel>? productDetails;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.unit,
    required this.categoryId,
    this.productImages,
    this.designViews,
    this.productDetails,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}
