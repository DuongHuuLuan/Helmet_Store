import 'package:b2205946_duonghuuluan_luanvan/data/models/product/product_detail_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_detail.dart';

class ProductDetailMapper {
  static ProductDetail fromModel(ProductDetailModel model) {
    return ProductDetail(
      id: model.id,
      colorId: model.colorId,
      colorName: model.colorName,
      colorHex: model.colorHex,
      sizeId: model.sizeId,
      size: model.sizeLabel,
      price: model.price,
      isActive: model.isActive,
    );
  }
}
