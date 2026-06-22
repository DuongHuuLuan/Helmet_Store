import 'package:b2205946_duonghuuluan_luanvan/data/mapper/product/product_detail_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/product/product_image_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/product/product_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';

class ProductMapper {
  static Product fromModel(ProductModel model) {
    return Product(
      id: model.id,
      name: model.name,
      description: model.description ?? "",
      unit: model.unit ?? "",
      categoryId: model.categoryId,
      images: (model.productImages ?? [])
          .map(ProductImageMapper.fromModel)
          .toList(),
      designViews: (model.designViews ?? [])
          .map(ProductImageMapper.fromModel)
          .toList(),
      productDetails: (model.productDetails ?? [])
          .map(ProductDetailMapper.fromModel)
          .toList(),
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}
