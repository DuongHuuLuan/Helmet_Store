import 'package:json_annotation/json_annotation.dart';

part 'sticker_template_model.g.dart';

@JsonSerializable()
class StickerTemplateModel {
  final int id;
  final String name;
  @JsonKey(name: 'image_url')
  final String imageUrl;
  final String? category;
  @JsonKey(name: 'is_ai_generated')
  final bool? isAiGenerated;
  @JsonKey(name: 'has_transparent_background')
  final bool? hasTransparentBackground;

  StickerTemplateModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.category,
    this.isAiGenerated,
    this.hasTransparentBackground,
  });

  factory StickerTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$StickerTemplateModelFromJson(json);

  Map<String, dynamic> toJson() => _$StickerTemplateModelToJson(this);
}
