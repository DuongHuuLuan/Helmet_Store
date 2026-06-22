import 'package:json_annotation/json_annotation.dart';
import '../product/product_detail_model.dart';

part 'cart_detail_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CartDetailModel {
  final int id;
  @JsonKey(name: 'product_detail_id')
  final int productDetailId;
  @JsonKey(name: 'design_id')
  final int? designId;
  @JsonKey(name: 'design_name')
  final String? designName;
  @JsonKey(name: 'design_preview_image_url')
  final String? designPreviewImageUrl;
  final int quantity;
  @JsonKey(name: 'product_detail')
  final ProductDetailModel productDetail;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'available_stock')
  final int availableStock;
  @JsonKey(name: 'cart_status')
  final String cartStatus;
  @JsonKey(name: 'status_message')
  final String? statusMessage;
  @JsonKey(name: 'can_checkout')
  final bool canCheckout;

  CartDetailModel({
    required this.id,
    required this.productDetailId,
    this.designId,
    this.designName,
    this.designPreviewImageUrl,
    required this.quantity,
    required this.productDetail,
    required this.isActive,
    required this.availableStock,
    required this.cartStatus,
    this.statusMessage,
    required this.canCheckout,
  });

  factory CartDetailModel.fromJson(Map<String, dynamic> json) =>
      _$CartDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$CartDetailModelToJson(this);
}
