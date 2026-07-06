import 'package:b2205946_duonghuuluan_luanvan/core/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/cubit/cart_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/chat/cubit/chat_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message_payload.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/chat/view/widget/chat_variant_picker.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/chat/view/widget/chat_variant_picker_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ChatProductCard extends StatelessWidget {
  final ChatProductCardData product;

  const ChatProductCard({super.key, required this.product});

  ChatProductActionData? get _viewDetailAction {
    for (final action in product.actions) {
      if (action.type == "view_detail") return action;
    }
    return null;
  }

  ChatProductActionData? get _addToCartAction {
    for (final action in product.actions) {
      if (action.type == "add_to_cart") return action;
    }
    return null;
  }

  List<ChatProductVariantData> get _availableVariants =>
      product.variants.where((variant) => variant.isAvailable).toList();

  int? get _fallbackSingleVariantId => _availableVariants.length == 1
      ? _availableVariants.first.productDetailId
      : null;

  void _openProduct(BuildContext context) {
    final action = _viewDetailAction;
    final target = (action?.target ?? "").trim();
    if (target.isNotEmpty) {
      context.push(target);
      return;
    }
    context.push("/products/${product.productId}");
  }

  Future<void> _addToCart(
    BuildContext context, {
    required int productDetailId,
  }) async {
    await context.read<ChatCubit>().addToCartAction(
      productDetailId: productDetailId,
    );
    if (context.mounted) {
      await context.read<CartCubit>().fetchCart();
    }
  }

  Future<void> _handleAddToCart(BuildContext context) async {
    final actionDetailId = _addToCartAction?.productDetailId;
    if (actionDetailId != null) {
      await _addToCart(context, productDetailId: actionDetailId);
      return;
    }

    final fallbackDetailId = _fallbackSingleVariantId;
    if (fallbackDetailId != null) {
      await _addToCart(context, productDetailId: fallbackDetailId);
      return;
    }

    if (_availableVariants.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sản phẩm này hiện chưa có biến thể còn hàng."),
        ),
      );
      return;
    }

    final selectedDetailId = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChatVariantPickerSheet(
        productName: product.name,
        variants: product.variants,
      ),
    );
    if (selectedDetailId == null || !context.mounted) return;
    await _addToCart(context, productDetailId: selectedDetailId);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = (product.imageUrl ?? "").trim();
    final priceText = product.price != null ? product.price!.toVnd() : null;
    final addActionLabel = _addToCartAction?.label ?? "Thêm vào giỏ";
    final showAddToCartButton =
        _addToCartAction?.productDetailId != null ||
        _availableVariants.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: imageUrl.isEmpty
                ? Container(
                    height: 148,
                    color: scheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 30,
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: 148,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => Container(
                      height: 148,
                      color: scheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((product.categoryName ?? "").trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      product.categoryName!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if ((product.categoryName ?? "").trim().isNotEmpty)
                  const SizedBox(height: 10),
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                if (priceText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    priceText,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ],
                if ((product.shortDescription ?? "").trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    product.shortDescription!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
                if (product.variants.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    "Biến thể nổi bật",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ChatVariantPicker(variants: product.variants),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openProduct(context),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(_viewDetailAction?.label ?? "Xem chi tiết"),
                    ),
                    if (showAddToCartButton)
                      FilledButton.icon(
                        onPressed: () async {
                          try {
                            await _handleAddToCart(context);
                          } catch (_) {
                            if (!context.mounted) return;
                            final error = context
                                .read<ChatCubit>()
                                .state
                                .errorMessage;
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    (error ?? "").trim().isNotEmpty
                                        ? error!.trim()
                                        : "Không thể thêm vào giỏ hàng.",
                                  ),
                                ),
                              );
                          }
                        },
                        icon: Icon(
                          _addToCartAction?.productDetailId != null ||
                                  _fallbackSingleVariantId != null
                              ? Icons.add_shopping_cart
                              : Icons.tune,
                          size: 18,
                        ),
                        label: Text(
                          _addToCartAction?.productDetailId != null ||
                                  _fallbackSingleVariantId != null
                              ? addActionLabel
                              : "Chọn biến thể",
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
