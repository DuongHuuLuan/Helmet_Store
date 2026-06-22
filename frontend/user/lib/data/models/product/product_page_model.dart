import 'package:json_annotation/json_annotation.dart';
import 'product_model.dart';

part 'product_page_model.g.dart';

@JsonSerializable()
class PaginationMeta {
  final int total;
  @JsonKey(name: 'current_page')
  final int currentPage;
  @JsonKey(name: 'per_page')
  final int perPage;
  @JsonKey(name: 'last_page')
  final int lastPage;

  PaginationMeta({
    required this.total,
    required this.currentPage,
    required this.perPage,
    required this.lastPage,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaFromJson(json);
  Map<String, dynamic> toJson() => _$PaginationMetaToJson(this);
}

@JsonSerializable()
class ProductPageModel {
  final List<ProductModel> items;
  final PaginationMeta meta;

  ProductPageModel({
    required this.items,
    required this.meta,
  });

  factory ProductPageModel.fromJson(Map<String, dynamic> json) =>
      _$ProductPageModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductPageModelToJson(this);
}
