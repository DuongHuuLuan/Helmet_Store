import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_detail.dart';

class Cart {
  final int id;
  final int userId;
  final List<CartDetail> cartDetails;
  final double totalPrice;
  final bool canCheckout;

  const Cart({
    required this.id,
    required this.userId,
    required this.cartDetails,
    required this.totalPrice,
    required this.canCheckout,
  });

  bool get isEmpty => cartDetails.isEmpty;
  bool get hasInvalidItems =>
      cartDetails.any((element) => !element.canCheckout);

  Cart copyWith({
    int? id,
    int? userId,
    List<CartDetail>? cartDetails,
    double? totalPrice,
    bool? canCheckout,
  }) {
    return Cart(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cartDetails: cartDetails ?? this.cartDetails,
      totalPrice: totalPrice ?? this.totalPrice,
      canCheckout: canCheckout ?? this.canCheckout,
    );
  }
}

class CartDetail {
  final int id;
  final int productDetailId;
  final int? designId;
  final String? designName;
  final String? designPreviewImageUrl;
  final int quantity;
  final ProductDetail productDetail;

  final bool isActive;
  final int availableStock;
  final String cartStatus;
  final String? statusMessage;
  final bool canCheckout;

  const CartDetail({
    required this.id,
    required this.productDetailId,
    this.designId,
    this.designName,
    this.designPreviewImageUrl,
    required this.quantity,
    required this.productDetail,
    required this.isActive,
    required this.availableStock,
    required this.cartStatus,
    required this.statusMessage,
    required this.canCheckout,
  });

  double get lineTotal => productDetail.price * quantity;
  bool get hasDesign => (designId ?? 0) > 0;

  bool get isInactive => cartStatus == "inactive";
  bool get isOutOfStock => cartStatus == "out_of_stock";
  bool get isInsufficientStock => cartStatus == "insufficient_stock";
  bool get isOk => cartStatus == "ok";
  bool get isLocked => !canCheckout;

  CartDetail copyWith({
    int? id,
    int? productDetailId,
    int? designId,
    String? designName,
    String? designPreviewImageUrl,
    int? quantity,
    ProductDetail? productDetail,
    bool? isActive,
    int? availableStock,
    String? cartStatus,
    String? statusMessage,
    bool? canCheckout,
  }) {
    return CartDetail(
      id: id ?? this.id,
      productDetailId: productDetailId ?? this.productDetailId,
      designId: designId ?? this.designId,
      designName: designName ?? this.designName,
      designPreviewImageUrl:
          designPreviewImageUrl ?? this.designPreviewImageUrl,
      quantity: quantity ?? this.quantity,
      productDetail: productDetail ?? this.productDetail,
      isActive: isActive ?? this.isActive,
      availableStock: availableStock ?? this.availableStock,
      cartStatus: cartStatus ?? this.cartStatus,
      statusMessage: statusMessage ?? this.statusMessage,
      canCheckout: canCheckout ?? this.canCheckout,
    );
  }
}
