import 'package:b2205946_duonghuuluan_luanvan/data/mapper/order/delivery_info_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/order/payment_method_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/order/order_detail_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/order/order_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/order_models.dart';

class OrderMapper {
  static OrderOut fromModel(OrderModel model) {
    final orderDetails = (model.orderDetails ?? []).map(_detailFromModel).toList();
    final subtotal = orderDetails.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    return OrderOut(
      id: model.id,
      status: model.status ?? "",
      paymentStatus: model.paymentStatus ?? "unpaid",
      refundSupportStatus: model.refundSupportStatus ?? "none",
      rejectionReason: model.rejectionReason,
      createdAt: model.createdAt,
      subtotal: subtotal,
      shippingFee: model.shippingFee ?? 0,
      total: subtotal + (model.shippingFee ?? 0),
      orderDetails: orderDetails,
      discountCode: model.discountCode,
      deliveryInfo:
          model.deliveryInfo != null ? DeliveryInfoMapper.fromModel(model.deliveryInfo!) : null,
      paymentMethod:
          model.paymentMethod != null ? PaymentMethodMapper.fromModel(model.paymentMethod!) : null,
    );
  }

  static OrderDetailOut _detailFromModel(OrderDetailModel model) {
    return OrderDetailOut(
      designId: model.designId,
      productDetailId: model.productDetailId,
      quantity: model.quantity,
      price: model.price,
      productName: model.productName ?? "Sản phẩm",
      colorName: model.colorName,
      sizeName: model.sizeName,
      imageUrl: model.imageUrl,
      designName: model.designName,
      designPreviewImageUrl: model.designPreviewImageUrl,
      stickerImageUrls: _extractStickerImageUrls(model.designSnapshotJson),
    );
  }

  static List<String> _extractStickerImageUrls(Map<String, dynamic>? snapshot) {
    if (snapshot == null) return const [];
    final rawLayers = snapshot["layers"];
    if (rawLayers is! List) return const [];
    final urls = <String>[];
    final seen = <String>{};
    for (final item in rawLayers) {
      if (item is! Map) continue;
      final url = item["image_url"]?.toString();
      if (url == null || !seen.add(url)) continue;
      urls.add(url);
    }
    return urls;
  }
}
