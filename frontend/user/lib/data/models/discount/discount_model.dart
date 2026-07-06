import 'package:json_annotation/json_annotation.dart';

part 'discount_model.g.dart';

@JsonSerializable()
class DiscountModel {
  final int id;
  @JsonKey(name: 'category_id')
  final int categoryId;
  final String name;
  final String? description;
  final double percent;
  @JsonKey(name: 'start_at')
  final DateTime? startAt;
  @JsonKey(name: 'end_at')
  final DateTime? endAt;
  final String? status;

  DiscountModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.percent,
    this.startAt,
    this.endAt,
    this.status,
  });

  factory DiscountModel.fromJson(Map<String, dynamic> json) =>
      _$DiscountModelFromJson(json);

  Map<String, dynamic> toJson() => _$DiscountModelToJson(this);
}
