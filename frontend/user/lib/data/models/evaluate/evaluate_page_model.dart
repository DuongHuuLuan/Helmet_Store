import 'package:json_annotation/json_annotation.dart';
import 'evaluate_item_model.dart';

part 'evaluate_page_model.g.dart';

@JsonSerializable()
class EvaluatePaginationMetaModel {
  final int page;
  @JsonKey(name: 'per_page')
  final int perPage;
  final int total;
  @JsonKey(name: 'total_pages')
  final int totalPages;

  EvaluatePaginationMetaModel({
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  factory EvaluatePaginationMetaModel.fromJson(Map<String, dynamic> json) =>
      _$EvaluatePaginationMetaModelFromJson(json);

  Map<String, dynamic> toJson() => _$EvaluatePaginationMetaModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class EvaluatePageModel {
  final List<EvaluateItemModel>? items;
  final EvaluatePaginationMetaModel meta;

  EvaluatePageModel({
    this.items,
    required this.meta,
  });

  int get page => meta.page;
  int get perPage => meta.perPage;
  int get total => meta.total;
  int get totalPages => meta.totalPages;

  factory EvaluatePageModel.fromJson(Map<String, dynamic> json) =>
      _$EvaluatePageModelFromJson(json);

  Map<String, dynamic> toJson() => _$EvaluatePageModelToJson(this);
}
