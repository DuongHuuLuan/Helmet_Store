import 'package:json_annotation/json_annotation.dart';

part 'evaluate_image_model.g.dart';

@JsonSerializable()
class EvaluateImageModel {
  final int id;
  @JsonKey(name: 'image_url')
  final String imageUrl;
  @JsonKey(name: 'sort_order')
  final int? sortOrder;

  EvaluateImageModel({
    required this.id,
    required this.imageUrl,
    this.sortOrder,
  });

  factory EvaluateImageModel.fromJson(Map<String, dynamic> json) =>
      _$EvaluateImageModelFromJson(json);

  Map<String, dynamic> toJson() => _$EvaluateImageModelToJson(this);
}
