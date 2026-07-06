import 'package:json_annotation/json_annotation.dart';
import 'evaluate_item_model.dart';
import 'evaluate_page_model.dart';

part 'product_evaluate_page_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProductEvaluateSummaryModel {
  @JsonKey(name: 'product_id')
  final int? productId;
  @JsonKey(name: 'average_rate')
  final double? averageRate;
  @JsonKey(name: 'total_evaluates')
  final int? totalEvaluates;
  @JsonKey(name: 'total_with_images')
  final int? totalWithImages;
  @JsonKey(name: 'summary_text')
  final String? summaryText;
  @JsonKey(name: 'rate_counts')
  final List<EvaluateRateCountModel>? rateCounts;

  ProductEvaluateSummaryModel({
    this.productId,
    this.averageRate,
    this.totalEvaluates,
    this.totalWithImages,
    this.summaryText,
    this.rateCounts,
  });

  factory ProductEvaluateSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$ProductEvaluateSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductEvaluateSummaryModelToJson(this);
}

@JsonSerializable()
class EvaluateRateCountModel {
  final int? star;
  final int? count;

  EvaluateRateCountModel({this.star, this.count});

  factory EvaluateRateCountModel.fromJson(Map<String, dynamic> json) =>
      _$EvaluateRateCountModelFromJson(json);

  Map<String, dynamic> toJson() => _$EvaluateRateCountModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductEvaluatePageModel {
  final ProductEvaluateSummaryModel? summary;
  final List<EvaluateItemModel>? items;
  final EvaluatePaginationMetaModel meta;

  ProductEvaluatePageModel({
    this.summary,
    this.items,
    required this.meta,
  });

  int get page => meta.page;
  int get perPage => meta.perPage;
  int get total => meta.total;
  int get totalPages => meta.totalPages;

  factory ProductEvaluatePageModel.fromJson(Map<String, dynamic> json) =>
      _$ProductEvaluatePageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductEvaluatePageModelToJson(this);
}
