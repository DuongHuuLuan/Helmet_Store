import 'package:json_annotation/json_annotation.dart';

part 'sticker_crop_model.g.dart';

@JsonSerializable()
class StickerCropModel {
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  StickerCropModel({this.left, this.top, this.right, this.bottom});

  factory StickerCropModel.fromJson(Map<String, dynamic> json) =>
      _$StickerCropModelFromJson(json);

  Map<String, dynamic> toJson() => _$StickerCropModelToJson(this);
}
