import 'package:b2205946_duonghuuluan_luanvan/core/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/helmet_designer/view/widget/design_sticker_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/profile/view/widget/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderHistoryList extends StatelessWidget {
  final List<OrderOut> orders;
  final String emptyMessage;
  final bool enableDetail;
  final Future<void> Function(OrderOut order)? onConfirmReceived;
  final Set<int> confirmingOrderIds;
  final Future<void> Function(OrderOut order)? onCancelOrder;
  final Set<int> cancellingOrderIds;
  final Set<int> evaluatedOrderIds;
  final Set<int> evaluatingOrderIds;
  final Future<void> Function(OrderOut order)? onCreateEvaluate;
  final Future<void> Function(OrderOut order)? onViewEvaluate;

  const OrderHistoryList({
    super.key,
    required this.orders,
    this.emptyMessage = "Bạn chưa có đơn hàng nào.",
    this.enableDetail = true,
    this.onConfirmReceived,
    this.confirmingOrderIds = const {},
    this.onCancelOrder,
    this.cancellingOrderIds = const {},
    this.evaluatedOrderIds = const {},
    this.evaluatingOrderIds = const {},
    this.onCreateEvaluate,
    this.onViewEvaluate,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(emptyMessage, textAlign: TextAlign.center),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final discountCode = order.discountCode?.trim() ?? "";
        final isConfirming = confirmingOrderIds.contains(order.id);
        final isCancelling = cancellingOrderIds.contains(order.id);
        final isEvaluated = evaluatedOrderIds.contains(order.id);
        final isEvaluating = evaluatingOrderIds.contains(order.id);
        final designedItems = order.orderDetails
            .where((item) => item.hasDesign)
            .toList(growable: false);
        final primaryDesignedItem = designedItems.isEmpty
            ? null
            : designedItems.first;
        final designSummary = designedItems.length <= 1
            ? primaryDesignedItem?.designName
            : "${designedItems.length} sản phẩm có thiết kế";

        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            onTap: enableDetail ? () => _showOrderDetail(context, order) : null,
            title: Text(
              "#DH-${order.id}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Ngày đặt: ${_formatDate(order.createdAt)}"),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaTag(
                      label: _paymentStatusLabel(order.paymentStatus),
                      foregroundColor: order.isPaid
                          ? Colors.green.shade800
                          : Colors.orange.shade900,
                      backgroundColor: order.isPaid
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                    ),
                    if (order.needsRefundChat)
                      _MetaTag(
                        label: "Liên hệ shop để hoàn tiền",
                        foregroundColor: Colors.red.shade800,
                        backgroundColor: Colors.red.shade50,
                      ),
                  ],
                ),
                if (discountCode.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Mã giảm giá: $discountCode",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (order.hasRejectionReason) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Lý do từ chối: ${order.rejectionReason!.trim()}",
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (primaryDesignedItem != null) ...[
                  const SizedBox(height: 8),
                  DesignStickerInfo(
                    designId: primaryDesignedItem.designId,
                    designName: designSummary,
                    designPreviewImageUrl:
                        primaryDesignedItem.designPreviewImageUrl,
                    stickerImageUrls: primaryDesignedItem.stickerImageUrls,
                    imageSize: 26,
                  ),
                ],
                if (_canConfirm(order) && onConfirmReceived != null) ...[
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: isConfirming
                        ? null
                        : () => _handleConfirmReceived(context, order),
                    child: Text(
                      isConfirming ? "Đang xử lý..." : "Đã nhận được hàng",
                    ),
                  ),
                ],
                if (_canCancel(order) && onCancelOrder != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: isCancelling
                        ? null
                        : () => _handleCancelOrder(context, order),
                    child: Text(
                      isCancelling ? "Đang xử lý..." : "Hủy đơn hàng",
                    ),
                  ),
                ],
                if (_canEvaluate(order) &&
                    ((!isEvaluated && onCreateEvaluate != null) ||
                        (isEvaluated && onViewEvaluate != null))) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: isEvaluating
                        ? null
                        : () => _handleEvaluateAction(
                            context,
                            order,
                            isEvaluated,
                          ),
                    icon: Icon(
                      isEvaluated
                          ? Icons.rate_review_outlined
                          : Icons.star_outline,
                    ),
                    label: Text(
                      isEvaluating
                          ? "Đang xử lý..."
                          : (isEvaluated ? "Xem đánh giá" : "Đánh giá"),
                    ),
                  ),
                ],
                if (order.needsRefundChat) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.push("/chat"),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text("Liên hệ shop hỗ trợ"),
                  ),
                ],
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(status: order.status),
                const SizedBox(height: 4),
                Text(
                  order.total.toVnd(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleConfirmReceived(
    BuildContext context,
    OrderOut order,
  ) async {
    final callback = onConfirmReceived;
    if (callback == null) return;

    final shouldConfirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Xác nhận nhận hàng"),
          content: Text("Bạn đã nhận thành công đơn hàng #DH-${order.id}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "Hủy",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text("Xác nhận"),
            ),
          ],
        );
      },
    );

    if (shouldConfirm == true) {
      await callback(order);
    }
  }

  Future<void> _handleCancelOrder(BuildContext context, OrderOut order) async {
    final callback = onCancelOrder;
    if (callback == null) return;

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Xác nhận hủy đơn hàng"),
          content: Text("Bạn có muốn hủy đơn hàng #DH-${order.id}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "Không",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Hủy đơn"),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true) {
      await callback(order);
    }
  }

  Future<void> _showOrderDetail(BuildContext context, OrderOut order) async {
    await context.push("/orders/${order.id}");
  }

  bool _canConfirm(OrderOut order) {
    return order.normalizedStatus == "shipping";
  }

  bool _canCancel(OrderOut order) {
    return order.normalizedStatus == "pending";
  }

  bool _canEvaluate(OrderOut order) {
    return order.normalizedStatus == "completed";
  }

  Future<void> _handleEvaluateAction(
    BuildContext context,
    OrderOut order,
    bool isEvaluated,
  ) async {
    final callback = isEvaluated ? onViewEvaluate : onCreateEvaluate;
    if (callback == null) return;
    await callback(order);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "--/--/----";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
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

class _MetaTag extends StatelessWidget {
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  const _MetaTag({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
