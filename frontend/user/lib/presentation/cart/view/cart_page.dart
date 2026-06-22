import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/discount/discount.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/view/widget/cart_actions.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/view/widget/cart_summary.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/view/widget/cart_table.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/view/widget/discount_dropdown.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/cubit/cart_cubit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Set<int> _selectedDiscountIds = {};
  final Set<int> _selectedCartDetailIds = {};
  bool _selectionTouched = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CartCubit>().fetchCart());
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CartCubit>();
    final vm = context.watch<CartCubit>().state;
    final cartDetails = vm.cartDetails;
    _ensureSelection(cartDetails);

    final selectedItems = cartDetails
        .where((detail) => _selectedCartDetailIds.contains(detail.id))
        .toList();

    final validSelectedItems = selectedItems
        .where((detail) => detail.canCheckout)
        .toList();

    final hasSelection = selectedItems.isNotEmpty;
    final hasInvalidSelection = selectedItems.any((e) => !e.canCheckout);

    final selectedTotal = validSelectedItems.fold<double>(
      0,
      (sum, detail) => sum + detail.lineTotal,
    );

    final selectableItems = cartDetails.where((e) => e.canCheckout).toList();
    final allSelected =
        selectableItems.isNotEmpty &&
        selectableItems.every(
          (detail) => _selectedCartDetailIds.contains(detail.id),
        );

    final selectedCategoryIds = validSelectedItems
        .map((detail) => cubit.categoryIdForDetail(detail.productDetailId))
        .whereType<int>()
        .toSet()
        .toList();

    _requestDiscounts(cubit, selectedCategoryIds);

    final availableDiscounts = vm.discounts;
    _syncSelectedDiscounts(availableDiscounts);

    final selectedDiscounts = availableDiscounts
        .where((discount) => _selectedDiscountIds.contains(discount.id))
        .toList();

    final discountByCategory = <int, double>{
      for (final discount in selectedDiscounts)
        discount.categoryId: discount.percent.toDouble(),
    };

    final selectedDiscountAmount = validSelectedItems.fold<double>(0, (
      sum,
      detail,
    ) {
      final categoryId = cubit.categoryIdForDetail(detail.productDetailId);
      final percent = categoryId == null
          ? 0.0
          : (discountByCategory[categoryId] ?? 0.0);
      return sum + (detail.lineTotal * (percent / 100));
    });

    final bool? selectAllValue = selectableItems.isEmpty
        ? false
        : allSelected
        ? true
        : _selectedCartDetailIds
              .where((id) => selectableItems.any((e) => e.id == id))
              .isEmpty
        ? false
        : null;

    final canProceedCheckout =
        hasSelection && !hasInvalidSelection && validSelectedItems.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Giỏ hàng", style: TextStyle(fontSize: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),

            if (cubit.hasInvalidItems) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text(
                  "Giỏ hàng có sản phẩm ngừng bán hoặc không đủ điều kiện mua. Vui lòng xóa các sản phẩm đó trước khi thanh toán.",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            _HeaderRow(
              selectAllValue: selectAllValue,
              onSelectAll: (value) => _toggleSelectAll(value, cartDetails),
            ),
            const SizedBox(height: 10),

            CartTable(
              cartDetails: cartDetails,
              isLoading: vm.isLoading,
              resolveProduct: cubit.productForDetail,
              onRemove: (id) => cubit.deleteCartDetail(cartDetailId: id),
              onUpdateQuantity: (id, quantity) =>
                  cubit.updateCartDetail(cartDetailId: id, newQuantity: quantity),
              isSelected: (id) => _selectedCartDetailIds.contains(id),
              onSelectChanged: _toggleSelectItem,
            ),
            const SizedBox(height: 16),

            CartActions(
              onContinue: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go("/");
                }
              },
              onRefresh: cubit.fetchCart,
              isLoading: vm.isLoading,
            ),
            const SizedBox(height: 20),

            CartSummary(
              total: selectedTotal,
              discountAmount: selectedDiscountAmount,
              appliedDiscountCount: selectedDiscounts.length,
            ),
            const SizedBox(height: 16),

            _CheckoutButton(
              onPressed: canProceedCheckout
                  ? () {
                      context.go(
                        "/order",
                        extra: {
                          "details": validSelectedItems,
                          "appliedDiscounts": selectedDiscounts,
                        },
                      );
                    }
                  : null,
            ),
            const SizedBox(height: 8),

            if (hasInvalidSelection)
              const Text(
                "Bạn đang chọn sản phẩm không thể thanh toán.",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 16),

            DiscountDropdown(
              discounts: availableDiscounts,
              isLoading: vm.isDiscountLoading,
              selectedIds: _selectedDiscountIds,
              onToggle: (discount, selected) =>
                  _toggleDiscount(discount, selected, availableDiscounts),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSelectAll(bool? value, List<CartDetail> cartDetails) {
    final selectableItems = cartDetails.where((e) => e.canCheckout).toList();

    setState(() {
      _selectionTouched = true;
      if (value == true) {
        _selectedCartDetailIds
          ..clear()
          ..addAll(selectableItems.map((detail) => detail.id));
      } else {
        _selectedCartDetailIds.removeWhere(
          (id) => selectableItems.any((detail) => detail.id == id),
        );
      }
    });
  }

  void _toggleSelectItem(int cartDetailId, bool selected) {
    setState(() {
      _selectionTouched = true;
      if (selected) {
        _selectedCartDetailIds.add(cartDetailId);
      } else {
        _selectedCartDetailIds.remove(cartDetailId);
      }
    });
  }

  void _toggleDiscount(
    Discount discount,
    bool selected,
    List<Discount> availableDiscounts,
  ) {
    setState(() {
      if (!selected) {
        _selectedDiscountIds.remove(discount.id);
        return;
      }

      final selectedById = {for (final d in availableDiscounts) d.id: d};
      _selectedDiscountIds.removeWhere((id) {
        final selectedDiscount = selectedById[id];
        if (selectedDiscount == null) return false;
        return selectedDiscount.categoryId == discount.categoryId;
      });
      _selectedDiscountIds.add(discount.id);
    });
  }

  void _requestDiscounts(CartCubit cubit, List<int> categoryIds) {
    final normalized = categoryIds.toSet();
    if (normalized.isEmpty) {
      if (_selectedDiscountIds.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _selectedDiscountIds.clear());
        });
      }
      if (cubit.state.discounts.isNotEmpty ||
          cubit.state.discountError != null ||
          cubit.state.isDiscountLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          cubit.fetchDiscountsForCategories(const []);
        });
      }
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      cubit.fetchDiscountsForCategories(normalized.toList());
    });
  }

  void _syncSelectedDiscounts(List<Discount> availableDiscounts) {
    final availableIds = availableDiscounts.map((d) => d.id).toSet();
    final needsCleanup = _selectedDiscountIds.any(
      (id) => !availableIds.contains(id),
    );
    if (!needsCleanup) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedDiscountIds.removeWhere((id) => !availableIds.contains(id));
      });
    });
  }

  void _ensureSelection(List<CartDetail> cartDetails) {
    final currentIds = cartDetails.map((detail) => detail.id).toSet();
    final validIds = cartDetails
        .where((detail) => detail.canCheckout)
        .map((detail) => detail.id)
        .toSet();

    final needsCleanup = _selectedCartDetailIds.any(
      (id) => !currentIds.contains(id),
    );
    final shouldAutoSelect =
        !_selectionTouched &&
        _selectedCartDetailIds.isEmpty &&
        validIds.isNotEmpty;

    if (!needsCleanup && !shouldAutoSelect) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        if (needsCleanup) {
          _selectedCartDetailIds.removeWhere((id) => !currentIds.contains(id));
        }
        if (shouldAutoSelect) {
          _selectedCartDetailIds.addAll(validIds);
        }
      });
    });
  }
}

class _HeaderRow extends StatelessWidget {
  final bool? selectAllValue;
  final ValueChanged<bool?> onSelectAll;

  const _HeaderRow({required this.selectAllValue, required this.onSelectAll});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final headerStyle = textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Checkbox(
                value: selectAllValue,
                tristate: true,
                onChanged: onSelectAll,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              Text("SẢN PHẨM", style: headerStyle),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            "SỐ LƯỢNG",
            textAlign: TextAlign.center,
            style: headerStyle,
          ),
        ),
      ],
    );
  }
}

class _CheckoutButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _CheckoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        child: const Text("TIẾN HÀNH THANH TOÁN"),
      ),
    );
  }
}
