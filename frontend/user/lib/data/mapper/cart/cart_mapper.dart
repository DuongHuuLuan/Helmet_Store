import 'package:b2205946_duonghuuluan_luanvan/data/mapper/product/product_detail_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/cart/cart_detail_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/cart/cart_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';

class CartMapper {
  static Cart fromModel(CartModel model) {
    return Cart(
      id: model.id,
      userId: model.userId,
      cartDetails: model.cartDetails.map(CartDetailMapper.fromModel).toList(),
      totalPrice: model.totalPrice,
      canCheckout: model.canCheckout,
    );
  }
}

class CartDetailMapper {
  static CartDetail fromModel(CartDetailModel model) {
    return CartDetail(
      id: model.id,
      productDetailId: model.productDetailId,
      designId: model.designId,
      designName: model.designName,
      designPreviewImageUrl: model.designPreviewImageUrl,
      quantity: model.quantity,
      productDetail: ProductDetailMapper.fromModel(model.productDetail),
      isActive: model.isActive,
      availableStock: model.availableStock,
      cartStatus: model.cartStatus,
      statusMessage: model.statusMessage,
      canCheckout: model.canCheckout,
    );
  }
}
