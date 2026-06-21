import 'package:json_annotation/json_annotation.dart';
import 'evaluate_item_model.dart';

part 'evaluate_page_model.g.dart';

@JsonSerializable(explicitToJson: true)
class EvaluatePageModel {
  final List<EvaluateItemModel>? items;
  final int? page;
  @JsonKey(name: 'per_page')
  final int? perPage;
  final int? total;
  @JsonKey(name: 'total_pages')
  final int? totalPages;

  EvaluatePageModel({
    this.items,
    this.page,
    this.perPage,
    this.total,
    this.totalPages,
  });

  factory EvaluatePageModel.fromJson(Map<String, dynamic> json) =>
      _$EvaluatePageModelFromJson(json);

  Map<String, dynamic> toJson() => _$EvaluatePageModelToJson(this);
}
