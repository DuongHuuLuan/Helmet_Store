import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_detail.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_image.dart';

class Product {
  final int id;
  final String name;
  final String description;
  final String unit;
  final int categoryId;
  final List<ProductImage> images;
  final List<ProductImage> designViews;
  final List<ProductDetail> productDetails;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.unit,
    required this.categoryId,
    required this.images,
    this.designViews = const [],
    required this.productDetails,
    this.createdAt,
    this.updatedAt,
  });
}
