import 'package:json_annotation/json_annotation.dart';
import 'evaluate_image_model.dart';

part 'evaluate_item_model.g.dart';

@JsonSerializable(explicitToJson: true)
class EvaluateItemModel {
  final int id;
  @JsonKey(name: 'order_id')
  final int orderId;
  @JsonKey(name: 'user_id')
  final int userId;
  final int rate;
  final String? content;
  @JsonKey(name: 'admin_reply')
  final String? adminReply;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'admin_replied_at')
  final DateTime? adminRepliedAt;
  final List<EvaluateImageModel>? images;
  @JsonKey(name: 'evaluater_name')
  final String? evaluaterName;
  @JsonKey(name: 'evaluater_name_masked')
  final String? evaluaterNameMasked;
  @JsonKey(name: 'matched_variants')
  final List<String>? matchedVariants;
  @JsonKey(name: 'has_images')
  final bool? hasImages;

  EvaluateItemModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.rate,
    this.content,
    this.adminReply,
    this.createdAt,
    this.updatedAt,
    this.adminRepliedAt,
    this.images,
    this.evaluaterName,
    this.evaluaterNameMasked,
    this.matchedVariants,
    this.hasImages,
  });

  factory EvaluateItemModel.fromJson(Map<String, dynamic> json) =>
      _$EvaluateItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$EvaluateItemModelToJson(this);
}
