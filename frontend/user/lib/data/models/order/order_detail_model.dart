import 'package:json_annotation/json_annotation.dart';

part 'order_detail_model.g.dart';

@JsonSerializable()
class OrderDetailModel {
  @JsonKey(name: 'design_id')
  final int? designId;
  @JsonKey(name: 'product_detail_id')
  final int productDetailId;
  final int quantity;
  final double price;
  @JsonKey(name: 'product_name')
  final String? productName;
  @JsonKey(name: 'color_name')
  final String? colorName;
  @JsonKey(name: 'size_name')
  final String? sizeName;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'design_name')
  final String? designName;
  @JsonKey(name: 'design_preview_image_url')
  final String? designPreviewImageUrl;
  @JsonKey(name: 'design_snapshot_json')
  final Map<String, dynamic>? designSnapshotJson;

  OrderDetailModel({
    this.designId,
    required this.productDetailId,
    required this.quantity,
    required this.price,
    this.productName,
    this.colorName,
    this.sizeName,
    this.imageUrl,
    this.designName,
    this.designPreviewImageUrl,
    this.designSnapshotJson,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderDetailModelToJson(this);
}
