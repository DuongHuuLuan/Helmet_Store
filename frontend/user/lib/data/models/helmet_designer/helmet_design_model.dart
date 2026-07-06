import 'package:json_annotation/json_annotation.dart';
import 'sticker_layer_model.dart';

part 'helmet_design_model.g.dart';

@JsonSerializable(explicitToJson: true)
class HelmetDesignModel {
  final int? id;
  @JsonKey(name: 'helmet_product_id')
  final int? helmetProductId;
  @JsonKey(name: 'product_detail_id')
  final int? productDetailId;
  @JsonKey(name: 'helmet_name')
  final String? helmetName;
  @JsonKey(name: 'helmet_base_image_url')
  final String? helmetBaseImageUrl;
  final List<StickerLayerModel>? stickers;
  @JsonKey(name: 'is_shared')
  final bool? isShared;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  HelmetDesignModel({
    this.id,
    this.helmetProductId,
    this.productDetailId,
    this.helmetName,
    this.helmetBaseImageUrl,
    this.stickers,
    this.isShared,
    this.createdAt,
    this.updatedAt,
  });

  factory HelmetDesignModel.fromJson(Map<String, dynamic> json) =>
      _$HelmetDesignModelFromJson(json);

  Map<String, dynamic> toJson() => _$HelmetDesignModelToJson(this);
}
