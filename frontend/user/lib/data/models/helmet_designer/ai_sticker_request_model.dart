import 'package:json_annotation/json_annotation.dart';

part 'ai_sticker_request_model.g.dart';

@JsonSerializable()
class AiStickerRequestModel {
  final String prompt;
  final String? style;
  @JsonKey(name: 'dominant_color')
  final String? dominantColor;
  @JsonKey(name: 'remove_background')
  final bool? removeBackground;

  AiStickerRequestModel({
    required this.prompt,
    this.style,
    this.dominantColor,
    this.removeBackground,
  });

  factory AiStickerRequestModel.fromJson(Map<String, dynamic> json) =>
      _$AiStickerRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$AiStickerRequestModelToJson(this);
}
