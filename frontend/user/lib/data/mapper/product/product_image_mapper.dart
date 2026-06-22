import 'package:b2205946_duonghuuluan_luanvan/data/models/product/product_image_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_image.dart';

class ProductImageMapper {
  static ProductImage fromModel(ProductImageModel model) {
    return ProductImage(
      id: model.id,
      url: model.url,
      publicId: model.publicId ?? "",
      colorId: model.colorId,
      viewImageKey: model.viewImageKey,
    );
  }
}
