import 'package:b2205946_duonghuuluan_luanvan/core/widgets/app_logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:b2205946_duonghuuluan_luanvan/core/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/cubit/cart_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/discount/discount.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/helmet_designer/view/widget/design_sticker_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_extension.dart';

class CartDrawer {
  static Future<void> show(BuildContext context, {int? productDetailId}) async {
    final vm = context.read<CartCubit>();
    await vm.fetchCart();
    final filteredDetails = productDetailId == null
        ? vm.state.cartDetails
        : vm.state.cartDetails
              .where((detail) => detail.productDetailId == productDetailId)
              .toList();
    final categoryIds = filteredDetails
        .map((detail) => vm.categoryIdForDetail(detail.productDetailId))
        .whereType<int>()
        .toSet()
        .toList();
    await vm.fetchDiscountsForCategories(categoryIds);

    await showGeneralDialog(
      context: context,
      barrierLabel: "cart_drawer",
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerLeft,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.84,
                child: _CartDrawerView(productDetailId: productDetailId),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}

class _CartDrawerView extends StatelessWidget {
  final int? productDetailId;
  const _CartDrawerView({this.productDetailId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(onClose: () => Navigator.of(context).pop()),
            const Divider(height: 1),
            Expanded(
              child: Builder(
                builder: (context) {
                  final cubit = context.read<CartCubit>();
                  final vm = context.watch<CartCubit>().state;
                  if (vm.isLoading) {
                    return const Center(
                      child: AppLogoLoader(size: 64, strokeWidth: 3.5),
                    );
                  }

                  final filteredDetails = productDetailId == null
                      ? vm.cartDetails
                      : vm.cartDetails
                            .where(
                              (detail) =>
                                  detail.productDetailId == productDetailId,
                            )
                            .toList();

                  if (filteredDetails.isEmpty) {
                    return const Center(child: Text("Giỏ hàng trống"));
                  }

                  final discountMap = _mapDiscounts(vm.discounts);
                  final total = _totalWithDiscounts(
                    filteredDetails,
                    discountMap,
                    cubit,
                  );

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredDetails.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final detail = filteredDetails[index];
                            final product = cubit.productForDetail(
                              detail.productDetailId,
                            );
                            return _CartItemCard(
                              detail: detail,
                              product: product,
                              discount: _discountForDetail(
                                detail,
                                cubit,
                                discountMap,
                              ),
                            );
                          },
                        ),
                      ),
                      _DrawerSummary(
                        total: total,
                        hasDiscount: discountMap.isNotEmpty,
                        onViewCart: () {
                          Navigator.of(context).pop();
                          context.go("/cart");
                        },
                        onContinue: () => Navigator.of(context).pop(),
                        onCheckout: () {
                          Navigator.of(context).pop();
                          context.go("/cart");
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<int, Discount> _mapDiscounts(List<Discount> discounts) {
    final map = <int, Discount>{};
    for (final discount in discounts) {
      map[discount.categoryId] = discount;
    }
    return map;
  }

  Discount? _discountForDetail(
    CartDetail detail,
    CartCubit cubit,
    Map<int, Discount> discountMap,
  ) {
    final categoryId = cubit.categoryIdForDetail(detail.productDetailId);
    if (categoryId == null) return null;
    return discountMap[categoryId];
  }

  double _totalWithDiscounts(
    List<CartDetail> details,
    Map<int, Discount> discountMap,
    CartCubit cubit,
  ) {
    double total = 0;
    for (final detail in details) {
      final price = detail.productDetail.price;
      final discount = _discountForDetail(detail, cubit, discountMap);
      final discountedPrice = discount == null
          ? price
          : price * (1 - (discount.percent / 100));
      total += discountedPrice * detail.quantity;
    }
    return total;
  }
}

class _DrawerHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _DrawerHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart, size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Giỏ hàng",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartDetail detail;
  final Product? product;
  final Discount? discount;

  const _CartItemCard({
    required this.detail,
    required this.product,
    required this.discount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final detailProduct = detail.productDetail;
    final imageUrl = product?.pickPrimaryImageUrl(detailProduct.colorId) ?? "";

    final price = detailProduct.price;
    final discountedPrice = discount == null
        ? price
        : price * (1 - (discount!.percent / 100));
    final lineTotal = discountedPrice * detail.quantity;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DrawerImage(url: imageUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.name ?? "Sản phẩm #${detail.productDetailId}",
                  maxLines: 2,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text("Màu sắc: ${detailProduct.colorName}"),
                Text("Kích cỡ: ${detailProduct.size}"),
                const SizedBox(height: 6),
                Text("Số lượng: ${detail.quantity}"),
                const SizedBox(height: 4),
                Text("Giá: ${discountedPrice.toVnd()}"),
                if (detail.hasDesign) ...[
                  const SizedBox(height: 8),
                  DesignStickerInfo(
                    designId: detail.designId,
                    designName: detail.designName,
                    designPreviewImageUrl: detail.designPreviewImageUrl,
                    imageSize: 28,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            lineTotal.toVnd(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _DrawerImage extends StatelessWidget {
  final String? url;
  const _DrawerImage({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.shopping_bag),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.shopping_bag),
        ),
        errorWidget: (context, url, error) => Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.shopping_bag),
        ),
      ),
    );
  }
}

class _DrawerSummary extends StatelessWidget {
  final double total;
  final bool hasDiscount;
  final VoidCallback onViewCart;
  final VoidCallback onContinue;
  final VoidCallback onCheckout;

  const _DrawerSummary({
    required this.total,
    required this.hasDiscount,
    required this.onViewCart,
    required this.onContinue,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          Text(
            "Tổng: ${total.toVnd()}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (hasDiscount) const SizedBox(height: 6),
          if (hasDiscount) const Text("Đã bao gồm mã giảm giá"),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewCart,
              child: const Text("Xem giỏ hàng"),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              child: const Text("Tiếp tục mua hàng"),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.onPrimary,
              ),
              child: Text("Thanh toán - ${total.toVnd()}"),
            ),
          ),
        ],
      ),
    );
  }
}
