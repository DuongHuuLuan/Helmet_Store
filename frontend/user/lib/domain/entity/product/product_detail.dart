class ProductDetail {
  final int id;
  final int colorId;
  final String colorName;
  final String colorHex;
  final int sizeId;
  final String size;
  final double price;
  final bool isActive;

  ProductDetail({
    required this.id,
    required this.colorId,
    required this.colorName,
    required this.colorHex,
    required this.sizeId,
    required this.size,
    required this.price,
    required this.isActive,
  });
}
