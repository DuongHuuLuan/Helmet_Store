import 'package:b2205946_duonghuuluan_luanvan/core/widgets/app_logo_loader.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/view/widget/cart_row.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:flutter/material.dart';

class CartTable extends StatelessWidget {
  final List<CartDetail> cartDetails;
  final bool isLoading;
  final void Function(int id) onRemove;
  final void Function(int id, int quantity) onUpdateQuantity;
  final Product? Function(int productDetailId) resolveProduct;
  final bool Function(int cartDetailId) isSelected;
  final void Function(int cartDetailId, bool selected) onSelectChanged;

  const CartTable({
    super.key,
    required this.cartDetails,
    required this.isLoading,
    required this.onRemove,
    required this.onUpdateQuantity,
    required this.resolveProduct,
    required this.isSelected,
    required this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading && cartDetails.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: AppLogoLoader(size: 64, strokeWidth: 3.5)),
            )
          else if (cartDetails.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "Giỏ hàng trống",
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cartDetails.length,
              separatorBuilder: (context, index) => Divider(
                height: 24,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final cartDetail = cartDetails[index];

                return CartRow(
                  cartDetail: cartDetail,
                  product: resolveProduct(cartDetail.productDetailId),
                  isBusy: isLoading,
                  onRemove: () => onRemove(cartDetail.id),
                  onUpdateQuantity: (quantity) =>
                      onUpdateQuantity(cartDetail.id, quantity),
                  isSelected: isSelected(cartDetail.id),
                  onSelectedChanged: cartDetail.canCheckout
                      ? (value) =>
                            onSelectChanged(cartDetail.id, value ?? false)
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }
}
