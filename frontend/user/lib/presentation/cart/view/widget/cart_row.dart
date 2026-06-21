import 'package:b2205946_duonghuuluan_luanvan/core/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/helmet_designer/view/widget/design_sticker_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_extension.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartRow extends StatelessWidget {
  final CartDetail cartDetail;
  final Product? product;
  final bool isBusy;
  final VoidCallback onRemove;
  final void Function(int quantity) onUpdateQuantity;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectedChanged;

  const CartRow({
    super.key,
    required this.cartDetail,
    required this.onRemove,
    required this.onUpdateQuantity,
    required this.product,
    required this.isBusy,
    required this.isSelected,
    required this.onSelectedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final detailProduct = cartDetail.productDetail;
    final imageUrl = product?.pickPrimaryImageUrl(detailProduct.colorId) ?? "";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: cartDetail.canCheckout ? isSelected : false,
                  onChanged: onSelectedChanged,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                _ProductImage(url: imageUrl),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product?.name ??
                            "Sản phẩm #${cartDetail.productDetailId}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusBadge(cartDetail: cartDetail),
                          if (cartDetail.statusMessage != null &&
                              cartDetail.statusMessage!.trim().isNotEmpty)
                            _StatusMessage(message: cartDetail.statusMessage!),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Text(
                        "Màu sắc: ${detailProduct.colorName}",
                        style: TextStyle(color: color.secondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Kích cỡ: ${detailProduct.size}",
                        style: TextStyle(color: color.secondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${cartDetail.quantity} x ${detailProduct.price.toVnd()}",
                        style: TextStyle(
                          color: color.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (cartDetail.hasDesign) ...[
                        const SizedBox(height: 10),
                        DesignStickerInfo(
                          designId: cartDetail.designId,
                          designName: cartDetail.designName,
                          designPreviewImageUrl:
                              cartDetail.designPreviewImageUrl,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 3),

          Expanded(
            flex: 3,
            child: _QuantityControl(
              onChanged: onUpdateQuantity,
              quantity: cartDetail.quantity,
              locked: cartDetail.isLocked || isBusy,
            ),
          ),

          const SizedBox(width: 5),
          _RemoveButton(onPressed: isBusy ? null : onRemove),
          const SizedBox(width: 3),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final CartDetail cartDetail;

  const _StatusBadge({required this.cartDetail});

  @override
  Widget build(BuildContext context) {
    if (!cartDetail.isInactive &&
        !cartDetail.isOutOfStock &&
        !cartDetail.isInsufficientStock) {
      return const SizedBox.shrink();
    }

    late final String text;
    late final Color bg;
    late final Color fg;

    if (cartDetail.isInactive) {
      text = "Ngừng bán";
      bg = Colors.grey.shade300;
      fg = Colors.grey.shade900;
    } else if (cartDetail.isOutOfStock) {
      text = "Hết hàng";
      bg = Colors.orange.shade100;
      fg = Colors.orange.shade900;
    } else if (cartDetail.isInsufficientStock) {
      text = "Vượt tồn";
      bg = Colors.amber.shade100;
      fg = Colors.amber.shade900;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final String message;

  const _StatusMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _RemoveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.outlineVariant),
          color: colorScheme.surfaceContainerHighest,
        ),
        child: Icon(Icons.close, size: 16, color: colorScheme.error),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? url;
  const _ProductImage({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _ImagePlaceholder();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        placeholder: (context, url) => _ImagePlaceholder(),
        errorWidget: (context, url, error) => _ImagePlaceholder(),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colorScheme.outline,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.surfaceContainerHigh),
      ),
      child: Icon(Icons.shopping_bag, color: colorScheme.secondary),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final bool locked;
  final void Function(int quantity) onChanged;

  const _QuantityControl({
    required this.onChanged,
    required this.quantity,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _QuantityButton(
          icon: Icons.remove,
          onPressed: locked
              ? null
              : quantity > 1
              ? () => onChanged(quantity - 1)
              : null,
        ),
        Container(
          width: 28,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: colorScheme.outline),
            ),
          ),
          child: Text(
            "$quantity",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        _QuantityButton(
          icon: Icons.add,
          onPressed: locked ? null : () => onChanged(quantity + 1),
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final disabled = onPressed == null;

    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(
            color: disabled ? colorScheme.outlineVariant : colorScheme.outline,
          ),
          color: disabled
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: disabled
              ? colorScheme.onSurfaceVariant
              : colorScheme.onSurface,
        ),
      ),
    );
  }
}
