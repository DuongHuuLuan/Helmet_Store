import 'package:json_annotation/json_annotation.dart';
import 'sticker_crop_model.dart';

part 'sticker_layer_model.g.dart';

@JsonSerializable(explicitToJson: true)
class StickerLayerModel {
  final int? id;
  @JsonKey(name: 'sticker_id')
  final int? stickerId;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final double? x;
  final double? y;
  final double? scale;
  final double? rotation;
  @JsonKey(name: 'z_index')
  final int? zIndex;
  @JsonKey(name: 'view_image_key')
  final String? viewImageKey;
  final StickerCropModel? crop;
  @JsonKey(name: 'tint_color_value')
  final int? tintColorValue;

  StickerLayerModel({
    this.id,
    this.stickerId,
    this.imageUrl,
    this.x,
    this.y,
    this.scale,
    this.rotation,
    this.zIndex,
    this.viewImageKey,
    this.crop,
    this.tintColorValue,
  });

  factory StickerLayerModel.fromJson(Map<String, dynamic> json) =>
      _$StickerLayerModelFromJson(json);

  Map<String, dynamic> toJson() => _$StickerLayerModelToJson(this);
}
