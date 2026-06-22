import 'package:b2205946_duonghuuluan_luanvan/core/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/cubit/cart_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/discount/discount.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/order/cubit/order_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/order/cubit/order_state.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/order/view/widget/address_form.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/order/view/widget/address_section.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/order/view/widget/payment_section.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/order/view/widget/payment_summary.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/order/view/widget/product_row.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class OrderPage extends StatefulWidget {
  final List<CartDetail> cartDetails;
  final List<Discount> appliedDiscounts;
  const OrderPage({
    super.key,
    required this.cartDetails,
    this.appliedDiscounts = const [],
  });

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  String _requiredNote = "KHONGCHOXEMHANG";

  @override
  void initState() {
    super.initState();
    final cubit = context.read<OrderCubit>();
    Future.microtask(() {
      cubit.setCartDetails(widget.cartDetails);
      cubit.loadInitialData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OrderCubit>().state;
    final cartCubit = context.read<CartCubit>();
    final discountByCategory = <int, double>{
      for (final d in widget.appliedDiscounts)
        d.categoryId: d.percent.toDouble(),
    };
    final subtotal = widget.cartDetails.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );
    final discountAmount = widget.cartDetails.fold<double>(0, (sum, item) {
      final categoryId = cartCubit.categoryIdForDetail(item.productDetailId);
      final percent = categoryId == null
          ? 0.0
          : (discountByCategory[categoryId] ?? 0.0);
      return sum + (item.lineTotal * (percent / 100));
    });
    final discountedTotal = subtotal - discountAmount;
    final shippingFee = state.feeTotal ?? 0;
    final totalPayment = discountedTotal + shippingFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán"),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go("/cart");
            }
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle("Địa chỉ nhận hàng"),
                AddressSection(
                  deliveries: state.deliveries,
                  selected: state.selectedDelivery,
                  useSaved: state.useSavedAddress,
                  onSelect: (info) => context.read<OrderCubit>().selectDelivery(info),
                  onUseNew: () => context.read<OrderCubit>().selectDelivery(null),
                ),
                if (!state.useSavedAddress || state.deliveries.isEmpty)
                  AddressForm(
                    nameController: _nameController,
                    phoneController: _phoneController,
                    addressController: _addressController,
                  ),
                if (!state.useSavedAddress || state.deliveries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      "Bạn có thể lưu địa chỉ mới trước khi đặt hàng, hoặc hệ thống sẽ tự lưu khi đơn hàng thành công.",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (!state.useSavedAddress || state.deliveries.isEmpty)
                  const _LocationSelectors(),
                if (!state.useSavedAddress || state.deliveries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : () => _saveNewAddress(state),
                        icon: state.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_location_alt_outlined),
                        label: Text(
                          state.isLoading ? "Đang lưu địa chỉ" : "Lưu địa chỉ mới",
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                _SectionTitle("Sản phẩm"),
                ...widget.cartDetails.map((item) {
                  final product = cartCubit.productForDetail(item.productDetailId);
                  return ProductRow(
                    detail: item,
                    product: product,
                    discountPercent: (() {
                      final categoryId = cartCubit.categoryIdForDetail(
                        item.productDetailId,
                      );
                      return categoryId == null
                          ? 0.0
                          : (discountByCategory[categoryId] ?? 0.0);
                    })(),
                  );
                }),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                _SectionTitle("Phương thức thanh toán"),
                PaymentSection(
                  methods: state.paymentMethods,
                  selected: state.selectedPayment,
                  onSelect: (value) {
                    if (value != null) {
                      context.read<OrderCubit>().selectPayment(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _SectionTitle("Chi tiết thanh toán"),
                PaymentSummary(
                  subtotal: subtotal,
                  discountAmount: discountAmount,
                  shippingFee: shippingFee,
                  total: totalPayment,
                ),
                const SizedBox(height: 20),
                _NoteSection(
                  noteController: _noteController,
                  requiredNote: _requiredNote,
                  onRequiredNoteChanged: (value) {
                    if (value == null) return;
                    setState(() => _requiredNote = value);
                  },
                ),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          _BottomBar(
            total: totalPayment,
            onPressed: state.isLoading ? null : () => _submit(state),
            isLoading: state.isLoading,
          ),
        ],
      ),
    );
  }

  Future<void> _submit(OrderState orderState) async {
    final useSaved = orderState.useSavedAddress && orderState.selectedDelivery != null;
    final name = useSaved
        ? orderState.selectedDelivery!.name
        : _nameController.text.trim();
    final phone = useSaved
        ? orderState.selectedDelivery!.phone
        : _phoneController.text.trim();
    final address = useSaved
        ? orderState.selectedDelivery!.address
        : _addressController.text.trim();

    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đủ thông tin nhận hàng")),
      );
      return;
    }

    final cubit = context.read<OrderCubit>();

    // Thực hiện đặt hàng
    final result = await cubit.submitOrder(
      name: name,
      phone: phone,
      address: address,
      note: _noteController.text.trim(),
      requiredNote: _requiredNote,
      discountIds: widget.appliedDiscounts.map((d) => d.id).toList(),
    );

    if (!mounted) return;

    if (cubit.state.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: ${cubit.state.errorMessage}")));
      return;
    }

    final url = result?.paymentUrl;

    if (url != null && url.isNotEmpty) {
      final orderId = cubit.state.lastOrderId ?? 0;
      if (orderId == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy mã đơn hàng")),
        );
        return;
      }

      context.go(
        "/order-result",
        extra: {"orderId": orderId, "paymentUrl": url},
      );
      return;
    }

    context.go("/order-success", extra: {"orderId": cubit.state.lastOrderId ?? 0});
  }

  Future<void> _saveNewAddress(OrderState orderState) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đủ thông tin địa chỉ mới")),
      );
      return;
    }

    final cubit = context.read<OrderCubit>();
    final delivery = await cubit.createDeliveryAddress(
      name: name,
      phone: phone,
      address: address,
    );

    if (!mounted) return;

    if (delivery == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cubit.state.errorMessage ?? "Không thể tạo địa chỉ giao hàng mới",
          ),
        ),
      );
      return;
    }

    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã lưu địa chỉ giao hàng mới")),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _LocationSelectors extends StatelessWidget {
  const _LocationSelectors();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OrderCubit>().state;
    final cubit = context.read<OrderCubit>();
    return Column(
      children: [
        _Dropdown<GhnProvince>(
          label: "Tỉnh/Thành",
          value: state.selectedProvince,
          items: state.provinces,
          itemLabel: (p) => p.provinceName,
          onChanged: (value) => cubit.selectProvince(value),
        ),
        _Dropdown<GhnDistrict>(
          label: "Quận/Huyện",
          value: state.selectedDistrict,
          items: state.districts,
          itemLabel: (d) => d.districtName,
          onChanged: (value) => cubit.selectDistrict(value),
        ),
        _Dropdown<GhnWard>(
          label: "Phường/Xã",
          value: state.selectedWard,
          items: state.wards,
          itemLabel: (w) => w.wardName,
          onChanged: (value) => cubit.selectWard(value),
        ),
      ],
    );
  }
}

class _NoteSection extends StatelessWidget {
  final TextEditingController noteController;
  final String requiredNote;
  final ValueChanged<String?> onRequiredNoteChanged;

  const _NoteSection({
    required this.noteController,
    required this.requiredNote,
    required this.onRequiredNoteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: noteController,
            decoration: InputDecoration(
              labelText: "Ghi chú",
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final double total;
  final VoidCallback? onPressed;
  final bool isLoading;
  const _BottomBar({
    required this.total,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Tổng cộng",
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    total.toVnd(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Đặt hàng"),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items
            .map(
              (item) =>
                  DropdownMenuItem(value: item, child: Text(itemLabel(item))),
            )
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
