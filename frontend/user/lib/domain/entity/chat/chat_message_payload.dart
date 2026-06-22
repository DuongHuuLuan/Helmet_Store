class ChatMessagePayload {
  final String kind;
  final String? title;
  final List<ChatProductCardData> products;
  final List<ChatDiscountData> discounts;
  final List<String> followUpSuggestions;
  final List<ChatProductActionData> actions;
  final String? noticeCode;
  final String? noticeMessage;
  final ChatCartActionResultData? cartActionResult;
  final ChatOrderSummaryData? order;

  const ChatMessagePayload({
    required this.kind,
    required this.title,
    required this.products,
    required this.discounts,
    required this.followUpSuggestions,
    required this.actions,
    required this.noticeCode,
    required this.noticeMessage,
    required this.cartActionResult,
    required this.order,
  });

  factory ChatMessagePayload.fromJson(Map<String, dynamic> json) {
    final products = json["products"];
    final discounts = json["discounts"];
    final suggestions = json["follow_up_suggestions"];
    final actions = json["actions"];
    final cartActionResult = json["cart_action_result"];
    final order = json["order"];
    return ChatMessagePayload(
      kind: json["kind"]?.toString() ?? "",
      title: json["title"]?.toString(),
      products: products is List
          ? products
                .whereType<Map>()
                .map(
                  (item) => ChatProductCardData.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      discounts: discounts is List
          ? discounts
                .whereType<Map>()
                .map(
                  (item) => ChatDiscountData.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      followUpSuggestions: suggestions is List
          ? suggestions.map((item) => item.toString()).toList()
          : const [],
      actions: actions is List
          ? actions
                .whereType<Map>()
                .map(
                  (item) => ChatProductActionData.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      noticeCode: json["notice_code"]?.toString(),
      noticeMessage: json["notice_message"]?.toString(),
      cartActionResult: cartActionResult is Map
          ? ChatCartActionResultData.fromJson(
              Map<String, dynamic>.from(cartActionResult),
            )
          : null,
      order: order is Map
          ? ChatOrderSummaryData.fromJson(Map<String, dynamic>.from(order))
          : null,
    );
  }
}

class ChatDiscountData {
  final int discountId;
  final int? categoryId;
  final String name;
  final String? description;
  final double percent;
  final String? status;
  final String? categoryName;
  final DateTime? startAt;
  final DateTime? endAt;

  const ChatDiscountData({
    required this.discountId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.percent,
    required this.status,
    required this.categoryName,
    required this.startAt,
    required this.endAt,
  });

  factory ChatDiscountData.fromJson(Map<String, dynamic> json) {
    return ChatDiscountData(
      discountId: _parseInt(json["discount_id"]) ?? 0,
      categoryId: _parseInt(json["category_id"]),
      name: json["name"]?.toString() ?? "",
      description: json["description"]?.toString(),
      percent: _parseDouble(json["percent"]) ?? 0,
      status: json["status"]?.toString(),
      categoryName: json["category_name"]?.toString(),
      startAt: _parseDate(json["start_at"]),
      endAt: _parseDate(json["end_at"]),
    );
  }
}

class ChatCartActionResultData {
  final String status;
  final int productDetailId;
  final String? productName;
  final String? imageUrl;
  final String? variantLabel;
  final int quantity;
  final String? message;

  const ChatCartActionResultData({
    required this.status,
    required this.productDetailId,
    required this.productName,
    required this.imageUrl,
    required this.variantLabel,
    required this.quantity,
    required this.message,
  });

  factory ChatCartActionResultData.fromJson(Map<String, dynamic> json) {
    return ChatCartActionResultData(
      status: json["status"]?.toString() ?? "",
      productDetailId: _parseInt(json["product_detail_id"]) ?? 0,
      productName: json["product_name"]?.toString(),
      imageUrl: json["image_url"]?.toString(),
      variantLabel: json["variant_label"]?.toString(),
      quantity: _parseInt(json["quantity"]) ?? 0,
      message: json["message"]?.toString(),
    );
  }
}

class ChatProductCardData {
  final int productId;
  final String name;
  final String? imageUrl;
  final double? price;
  final String? shortDescription;
  final String? categoryName;
  final List<ChatProductVariantData> variants;
  final List<ChatProductActionData> actions;

  const ChatProductCardData({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.shortDescription,
    required this.categoryName,
    required this.variants,
    required this.actions,
  });

  factory ChatProductCardData.fromJson(Map<String, dynamic> json) {
    final variants = json["variants"];
    final actions = json["actions"];
    return ChatProductCardData(
      productId: _parseInt(json["product_id"]) ?? 0,
      name: json["name"]?.toString() ?? "",
      imageUrl: json["image_url"]?.toString(),
      price: _parseDouble(json["price"]),
      shortDescription: json["short_description"]?.toString(),
      categoryName: json["category_name"]?.toString(),
      variants: variants is List
          ? variants
                .whereType<Map>()
                .map(
                  (item) => ChatProductVariantData.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      actions: actions is List
          ? actions
                .whereType<Map>()
                .map(
                  (item) => ChatProductActionData.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class ChatProductVariantData {
  final int productDetailId;
  final int? colorId;
  final String? colorName;
  final int? sizeId;
  final String? sizeName;
  final int stock;
  final bool isAvailable;

  const ChatProductVariantData({
    required this.productDetailId,
    required this.colorId,
    required this.colorName,
    required this.sizeId,
    required this.sizeName,
    required this.stock,
    required this.isAvailable,
  });

  factory ChatProductVariantData.fromJson(Map<String, dynamic> json) {
    return ChatProductVariantData(
      productDetailId: _parseInt(json["product_detail_id"]) ?? 0,
      colorId: _parseInt(json["color_id"]),
      colorName: json["color_name"]?.toString(),
      sizeId: _parseInt(json["size_id"]),
      sizeName: json["size_name"]?.toString(),
      stock: _parseInt(json["stock"]) ?? 0,
      isAvailable: json["is_available"] == true,
    );
  }
}

class ChatProductActionData {
  final String type;
  final String label;
  final String? target;
  final int? productDetailId;

  const ChatProductActionData({
    required this.type,
    required this.label,
    required this.target,
    required this.productDetailId,
  });

  factory ChatProductActionData.fromJson(Map<String, dynamic> json) {
    return ChatProductActionData(
      type: json["type"]?.toString() ?? "",
      label: json["label"]?.toString() ?? "",
      target: json["target"]?.toString(),
      productDetailId: _parseInt(json["product_detail_id"]),
    );
  }
}

class ChatOrderSummaryData {
  final int orderId;
  final String status;
  final String? statusLabel;
  final String paymentStatus;
  final String? paymentStatusLabel;
  final String refundSupportStatus;
  final String? refundSupportStatusLabel;
  final DateTime? createdAt;
  final double shippingFee;
  final double totalAmount;
  final int totalItems;
  final String? paymentMethodName;
  final String? recipientName;
  final String? recipientPhone;
  final String? deliveryAddress;
  final List<ChatOrderItemData> items;

  const ChatOrderSummaryData({
    required this.orderId,
    required this.status,
    required this.statusLabel,
    required this.paymentStatus,
    required this.paymentStatusLabel,
    required this.refundSupportStatus,
    required this.refundSupportStatusLabel,
    required this.createdAt,
    required this.shippingFee,
    required this.totalAmount,
    required this.totalItems,
    required this.paymentMethodName,
    required this.recipientName,
    required this.recipientPhone,
    required this.deliveryAddress,
    required this.items,
  });

  factory ChatOrderSummaryData.fromJson(Map<String, dynamic> json) {
    final items = json["items"];
    return ChatOrderSummaryData(
      orderId: _parseInt(json["order_id"]) ?? 0,
      status: json["status"]?.toString() ?? "",
      statusLabel: json["status_label"]?.toString(),
      paymentStatus: json["payment_status"]?.toString() ?? "",
      paymentStatusLabel: json["payment_status_label"]?.toString(),
      refundSupportStatus: json["refund_support_status"]?.toString() ?? "",
      refundSupportStatusLabel: json["refund_support_status_label"]?.toString(),
      createdAt: _parseDate(json["created_at"]),
      shippingFee: _parseDouble(json["shipping_fee"]) ?? 0,
      totalAmount: _parseDouble(json["total_amount"]) ?? 0,
      totalItems: _parseInt(json["total_items"]) ?? 0,
      paymentMethodName: json["payment_method_name"]?.toString(),
      recipientName: json["recipient_name"]?.toString(),
      recipientPhone: json["recipient_phone"]?.toString(),
      deliveryAddress: json["delivery_address"]?.toString(),
      items: items is List
          ? items
                .whereType<Map>()
                .map(
                  (item) => ChatOrderItemData.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class ChatOrderItemData {
  final String productName;
  final String? imageUrl;
  final String? colorName;
  final String? sizeName;
  final int quantity;
  final double unitPrice;

  const ChatOrderItemData({
    required this.productName,
    required this.imageUrl,
    required this.colorName,
    required this.sizeName,
    required this.quantity,
    required this.unitPrice,
  });

  factory ChatOrderItemData.fromJson(Map<String, dynamic> json) {
    return ChatOrderItemData(
      productName: json["product_name"]?.toString() ?? "",
      imageUrl: json["image_url"]?.toString(),
      colorName: json["color_name"]?.toString(),
      sizeName: json["size_name"]?.toString(),
      quantity: _parseInt(json["quantity"]) ?? 0,
      unitPrice: _parseDouble(json["unit_price"]) ?? 0,
    );
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
