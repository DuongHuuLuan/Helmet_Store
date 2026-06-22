import 'package:b2205946_duonghuuluan_luanvan/data/models/product/product_page_model.dart';
import 'package:json_annotation/json_annotation.dart';

import 'category_model.dart';

part 'category_page_model.g.dart';

@JsonSerializable()
class CategoryPageModel {
  final List<CategoryModel> items;
  final PaginationMeta meta;

  CategoryPageModel({required this.items, required this.meta});

  factory CategoryPageModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryPageModelFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryPageModelToJson(this);
}
