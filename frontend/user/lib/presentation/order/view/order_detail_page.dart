import 'package:b2205946_duonghuuluan_luanvan/core/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/widgets/app_logo_loader.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/evaluate/view/evaluate_create_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/evaluate/cubit/evaluate_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/helmet_designer/view/widget/design_sticker_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/injection_container.dart' as di;
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_order_detail_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/profile/cubit/profile_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/profile/view/widget/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  OrderOut? _order;
  bool _isLoading = true;
  bool _isActing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadOrder);
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await di.getIt<GetOrderDetailUseCase>()(
      widget.orderId,
    );
    result.fold(
      (failure) {
        if (!mounted) return;
        setState(() => _error = failure.message);
      },
      (order) {
        if (!mounted) return;
        setState(() => _order = order);
        _syncEvaluateStatus(order.id);
      },
    );
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncEvaluateStatus(int orderId) async {
    try {
      await context.read<EvaluateCubit>().syncEvaluateStatusForOrders([
        orderId,
      ]);
    } catch (_) {}
  }

  Future<void> _confirmReceived() async {
    final order = _order;
    if (order == null || order.normalizedStatus != "shipping" || _isActing) {
      return;
    }

    final shouldConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận nhận hàng"),
        content: Text("Bạn đã nhận thành công đơn hàng #DH-${order.id}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Hủy"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
    if (shouldConfirm != true) return;

    setState(() => _isActing = true);
    try {
      await context.read<ProfileCubit>().confirmOrderReceived(order.id);
      await _loadOrder();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xác nhận nhận hàng thành công.")),
      );
    } catch (_) {
      if (!mounted) return;
      final msg =
          context.read<ProfileCubit>().state.errorMessage ??
          "Xác nhận nhận hàng thất bại.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _cancelOrder() async {
    final order = _order;
    if (order == null || order.normalizedStatus != "pending" || _isActing) {
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận hủy đơn hàng"),
        content: Text("Bạn có muốn hủy đơn hàng #DH-${order.id}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Không",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Hủy đơn"),
          ),
        ],
      ),
    );
    if (shouldCancel != true) return;

    setState(() => _isActing = true);
    try {
      await context.read<ProfileCubit>().cancelOrder(order.id);
      await _loadOrder();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã hủy đơn hàng thành công.")),
      );
    } catch (_) {
      if (!mounted) return;
      final msg =
          context.read<ProfileCubit>().state.errorMessage ??
          "Hủy đơn hàng thất bại.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _createEvaluate() async {
    final order = _order;
    if (order == null || order.normalizedStatus != "completed" || _isActing) {
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EvaluateCreatePage(orderId: order.id)),
    );
    if (result == true && mounted) {
      await _syncEvaluateStatus(order.id);
    }
  }

  Future<void> _openSupportChat() async {
    if (!mounted) return;
    await context.push("/chat");
    if (!mounted) return;
    await _loadOrder();
  }

  String _safeText(String? value) {
    final text = value?.trim() ?? "";
    return text.isEmpty ? "Chưa có" : text;
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final evaluateCubit = context.read<EvaluateCubit>();
    final isReviewed =
        order != null && evaluateCubit.reviewedOrderIds.contains(order.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          order == null ? "Chi tiết đơn hàng" : "Đơn hàng #DH-${order.id}",
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadOrder,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLogoLoader(size: 80, strokeWidth: 4))
          : _error != null
          ? _ErrorView(message: _error!, onRetry: _loadOrder)
          : order == null
          ? _ErrorView(message: "Không tìm thấy đơn hàng.", onRetry: _loadOrder)
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OrderHeaderCard(order: order),
                    if (order.hasRejectionReason) ...[
                      const SizedBox(height: 12),
                      _NoticeCard(
                        icon: Icons.cancel_outlined,
                        backgroundColor: Colors.red.shade50,
                        iconColor: Colors.red.shade700,
                        title: "Lý do từ chối đơn",
                        message: order.rejectionReason!.trim(),
                      ),
                    ],
                    if (order.needsRefundChat) ...[
                      const SizedBox(height: 12),
                      _NoticeCard(
                        icon: Icons.support_agent,
                        backgroundColor: Colors.orange.shade50,
                        iconColor: Colors.orange.shade800,
                        title: "Cần liên hệ shop để hoàn tiền",
                        message:
                            "Đơn hàng này đã thanh toán và cần trao đổi với quản trị viên qua chat để xử lý hoàn tiền.",
                        action: TextButton.icon(
                          onPressed: _openSupportChat,
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text("Mở cuộc hội thoại hỗ trợ"),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: "Thông tin người đặt",
                      child: _InfoList(
                        rows: [
                          _InfoRowData(
                            label: "Người nhận",
                            value: _safeText(order.deliveryInfo?.name),
                          ),
                          _InfoRowData(
                            label: "Số điện thoại",
                            value: _safeText(order.deliveryInfo?.phone),
                          ),
                          _InfoRowData(
                            label: "Địa chỉ",
                            value: _safeText(order.deliveryInfo?.address),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: "Thanh toán và vận chuyển",
                      child: _InfoList(
                        rows: [
                          _InfoRowData(
                            label: "Phương thức thanh toán",
                            value: _safeText(order.paymentMethod?.name),
                          ),
                          _InfoRowData(
                            label: "Trạng thái thanh toán",
                            value: _paymentStatusLabel(order.paymentStatus),
                          ),
                          _InfoRowData(
                            label: "Hỗ trợ hoàn tiền",
                            value: _refundSupportLabel(
                              order.refundSupportStatus,
                            ),
                          ),
                          _InfoRowData(
                            label: "Mã giảm giá",
                            value: (order.discountCode ?? "").trim().isEmpty
                                ? "Không áp dụng"
                                : order.discountCode!.trim(),
                          ),
                          _InfoRowData(
                            label: "Phí vận chuyển",
                            value: order.shippingFee.toVnd(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: "Sản phẩm",
                      child: order.orderDetails.isEmpty
                          ? const Text("Không có sản phẩm trong đơn hàng.")
                          : Column(
                              children: order.orderDetails
                                  .map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _OrderProductTile(detail: item),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: "Tổng tiền",
                      child: _TotalBox(order: order),
                    ),
                    const SizedBox(height: 16),
                    _ActionSection(
                      order: order,
                      isBusy: _isActing,
                      isReviewed: isReviewed,
                      onCancel: _cancelOrder,
                      onConfirmReceived: _confirmReceived,
                      onEvaluate: _createEvaluate,
                      onOpenChat: _openSupportChat,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => context.go("/"),
                      child: const Text("Về trang chủ"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

String _paymentStatusLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case "paid":
      return "Đã thanh toán";
    case "unpaid":
      return "Chưa thanh toán";
    default:
      return "Không rõ";
  }
}

String _refundSupportLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case "contact_required":
      return "Liên hệ shop để hoàn tiền";
    case "resolved":
      return "Đã xử lý";
    case "none":
      return "Không yêu cầu";
    default:
      return "Không rõ";
  }
}

class _OrderHeaderCard extends StatelessWidget {
  final OrderOut order;

  const _OrderHeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final date = order.createdAt;
    final dateText = date == null
        ? "--/--/----"
        : "${date.day.toString().padLeft(2, "0")}/${date.month.toString().padLeft(2, "0")}/${date.year} ${date.hour.toString().padLeft(2, "0")}:${date.minute.toString().padLeft(2, "0")}";

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "#DH-${order.id}",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip(status: order.status),
                _MetaChip(
                  label: _paymentStatusLabel(order.paymentStatus),
                  icon: order.isPaid ? Icons.payments : Icons.money_off_csred,
                  foregroundColor: order.isPaid
                      ? Colors.green.shade800
                      : Colors.orange.shade900,
                  backgroundColor: order.isPaid
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                ),
                if (order.needsRefundChat)
                  _MetaChip(
                    label: _refundSupportLabel(order.refundSupportStatus),
                    icon: Icons.support_agent,
                    foregroundColor: Colors.red.shade800,
                    backgroundColor: Colors.red.shade50,
                  ),
                Text("Ngày đặt: $dateText"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final String title;
  final String message;
  final Widget? action;

  const _NoticeCard({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                  if (action != null) ...[const SizedBox(height: 8), action!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;

  const _MetaChip({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRowData {
  final String label;
  final String value;

  const _InfoRowData({required this.label, required this.value});
}

class _InfoList extends StatelessWidget {
  final List<_InfoRowData> rows;

  const _InfoList({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 138,
                    child: Text(
                      row.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      row.value,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _OrderProductTile extends StatelessWidget {
  final OrderDetailOut detail;

  const _OrderProductTile({required this.detail});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (detail.imageUrl ?? "").trim();
    final lineTotal = detail.quantity * detail.price;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 72,
            height: 72,
            color: Colors.grey.shade100,
            child: imageUrl.isEmpty
                ? const Icon(Icons.image_not_supported_outlined)
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.productName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _variantText(detail),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                "Số lượng: ${detail.quantity}",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                "Đơn giá: ${detail.price.toVnd()}",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (detail.hasDesign) ...[
                const SizedBox(height: 8),
                DesignStickerInfo(
                  designId: detail.designId,
                  designName: detail.designName,
                  designPreviewImageUrl: detail.designPreviewImageUrl,
                  stickerImageUrls: detail.stickerImageUrls,
                ),
              ],
              const SizedBox(height: 2),
              Text(
                "Thành tiền: ${lineTotal.toVnd()}",
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _variantText(OrderDetailOut item) {
    final parts = <String>[];
    final color = (item.colorName ?? "").trim();
    final size = (item.sizeName ?? "").trim();
    if (color.isNotEmpty) parts.add("Màu: $color");
    if (size.isNotEmpty) parts.add("Kích thước: $size");
    return parts.isEmpty ? "Biến thể: --" : parts.join(" | ");
  }
}

class _TotalBox extends StatelessWidget {
  final OrderOut order;

  const _TotalBox({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _totalRow("Tiền hàng", order.subtotal.toVnd()),
        const SizedBox(height: 6),
        _totalRow("Phí vận chuyển", order.shippingFee.toVnd()),
        const Divider(height: 18),
        _totalRow("Tổng thanh toán", order.total.toVnd(), isTotal: true),
      ],
    );
  }

  Widget _totalRow(String label, String value, {bool isTotal = false}) {
    return Builder(
      builder: (context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isTotal ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  final OrderOut order;
  final bool isBusy;
  final bool isReviewed;
  final VoidCallback onCancel;
  final VoidCallback onConfirmReceived;
  final VoidCallback onEvaluate;
  final VoidCallback onOpenChat;

  const _ActionSection({
    required this.order,
    required this.isBusy,
    required this.isReviewed,
    required this.onCancel,
    required this.onConfirmReceived,
    required this.onEvaluate,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (order.normalizedStatus == "pending") {
      children.add(
        FilledButton.tonal(
          onPressed: isBusy ? null : onCancel,
          child: Text(isBusy ? "Đang xử lý..." : "Hủy đơn hàng"),
        ),
      );
    }

    if (order.normalizedStatus == "shipping") {
      children.add(
        FilledButton(
          onPressed: isBusy ? null : onConfirmReceived,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
          child: Text(isBusy ? "Đang xử lý..." : "Đã nhận được hàng"),
        ),
      );
    }

    if (order.normalizedStatus == "completed") {
      children.add(
        OutlinedButton.icon(
          onPressed: isBusy || isReviewed ? null : onEvaluate,
          icon: Icon(
            isReviewed ? Icons.check_circle_outline : Icons.star_outline,
          ),
          label: Text(isReviewed ? "Đã đánh giá" : "Đánh giá"),
        ),
      );
    }

    if (order.needsRefundChat) {
      children.add(
        OutlinedButton.icon(
          onPressed: onOpenChat,
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text("Liên hệ shop để hoàn tiền"),
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Thao tác",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...children.map(
          (widget) =>
              Padding(padding: const EdgeInsets.only(bottom: 8), child: widget),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text("Tải lại")),
          ],
        ),
      ),
    );
  }
}
