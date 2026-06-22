import 'package:b2205946_duonghuuluan_luanvan/core/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/helmet_designer/view/widget/design_sticker_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_extension.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductRow extends StatelessWidget {
  final CartDetail detail;
  final Product? product;
  final double discountPercent;
  const ProductRow({
    super.key,
    required this.detail,
    required this.product,
    required this.discountPercent,
  });

  @override
  Widget build(BuildContext context) {
    final original = detail.productDetail.price;
    final discounted = original * (1 - discountPercent / 100);
    final productImageUrl = _resolveImageUrl();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: productImageUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(productImageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: productImageUrl == null
                  ? const Icon(Icons.image_not_supported_outlined)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.name ?? "Sản phẩm",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        discounted.toVnd(),
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (discountPercent > 0)
                        Text(
                          original.toVnd(),
                          style: const TextStyle(
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  if (detail.hasDesign) ...[
                    const SizedBox(height: 8),
                    DesignStickerInfo(
                      designId: detail.designId,
                      designName: detail.designName,
                      designPreviewImageUrl: detail.designPreviewImageUrl,
                    ),
                  ],
                ],
              ),
            ),
            Text("x${detail.quantity}"),
          ],
        ),
      ),
    );
  }

  String? _resolveImageUrl() {
    if (product == null || product!.images.isEmpty) return null;
    return product!.pickPrimaryImageUrl(detail.productDetail.colorId);
  }
}
