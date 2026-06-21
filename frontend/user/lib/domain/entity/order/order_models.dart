import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/delivery_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/payment_method.dart';

class OrderItemCreate {
  final int cartDetailId;
  final int productDetailId;
  final int quantity;

  const OrderItemCreate({
    required this.cartDetailId,
    required this.productDetailId,
    required this.quantity,
  });
}

class OrderCreate {
  final int deliveryInfoId;
  final int paymentMethodId;
  final List<OrderItemCreate> items;
  final List<int> discountIds;

  const OrderCreate({
    required this.deliveryInfoId,
    required this.paymentMethodId,
    required this.items,
    this.discountIds = const [],
  });
}

class OrderDetailOut {
  final int? designId;
  final int productDetailId;
  final int quantity;
  final double price;
  final String productName;
  final String? colorName;
  final String? sizeName;
  final String? imageUrl;
  final String? designName;
  final String? designPreviewImageUrl;
  final List<String> stickerImageUrls;

  const OrderDetailOut({
    this.designId,
    required this.productDetailId,
    required this.quantity,
    required this.price,
    required this.productName,
    this.colorName,
    this.sizeName,
    this.imageUrl,
    this.designName,
    this.designPreviewImageUrl,
    this.stickerImageUrls = const [],
  });

  bool get hasDesign => (designId ?? 0) > 0;
}

class OrderOut {
  final int id;
  final String status;
  final String paymentStatus;
  final String refundSupportStatus;
  final String? rejectionReason;
  final DateTime? createdAt;
  final double subtotal;
  final double shippingFee;
  final double total;
  final List<OrderDetailOut> orderDetails;
  final String? discountCode;
  final DeliveryInfo? deliveryInfo;
  final PaymentMethod? paymentMethod;

  const OrderOut({
    required this.id,
    required this.status,
    this.paymentStatus = "unpaid",
    this.refundSupportStatus = "none",
    this.rejectionReason,
    this.createdAt,
    this.subtotal = 0,
    this.shippingFee = 0,
    this.total = 0,
    this.orderDetails = const [],
    this.discountCode,
    this.deliveryInfo,
    this.paymentMethod,
  });

  String get normalizedStatus => status.trim().toLowerCase();
  String get normalizedPaymentStatus => paymentStatus.trim().toLowerCase();
  String get normalizedRefundSupportStatus =>
      refundSupportStatus.trim().toLowerCase();

  bool get isPaid => normalizedPaymentStatus == "paid";
  bool get isCancelled => normalizedStatus == "cancelled";
  bool get isPendingReview => normalizedStatus == "pending" && isPaid;
  bool get needsRefundChat =>
      normalizedRefundSupportStatus == "contact_required";
  bool get hasRejectionReason => (rejectionReason ?? "").trim().isNotEmpty;
}
