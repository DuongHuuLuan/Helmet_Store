import 'package:b2205946_duonghuuluan_luanvan/core/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/constants/app_constants.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/profile/view/widget/status_chip.dart';
import 'package:flutter/material.dart';

class ProfileOrderCard extends StatelessWidget {
  final OrderOut order;
  final bool isEvaluated;
  final bool isConfirming;
  final bool isCancelling;
  final bool isEvaluating;
  final VoidCallback? onOpenDetail;
  final Future<void> Function(OrderOut order)? onConfirmReceived;
  final Future<void> Function(OrderOut order)? onCancelOrder;
  final Future<void> Function(OrderOut order)? onCreateEvaluate;
  final Future<void> Function(OrderOut order)? onViewEvaluate;
  final VoidCallback? onOpenSupportChat;

  const ProfileOrderCard({
    super.key,
    required this.order,
    required this.isEvaluated,
    required this.isConfirming,
    required this.isCancelling,
    required this.isEvaluating,
    this.onOpenDetail,
    this.onConfirmReceived,
    this.onCancelOrder,
    this.onCreateEvaluate,
    this.onViewEvaluate,
    this.onOpenSupportChat,
  });

  @override
  Widget build(BuildContext context) {
    final previews = order.orderDetails.take(2).toList(growable: false);
    final remaining = order.orderDetails.length - previews.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenDetail,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "#DH-${order.id}",
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(order.createdAt),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF697487)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    StatusChip(status: order.status),
                  ],
                ),
                if ((order.discountCode ?? "").trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      "Voucher: ${order.discountCode!.trim()}",
                      style: const TextStyle(
                        color: Color(0xFFD97A18),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (previews.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ...previews.map(
                    (detail) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OrderItemPreview(detail: detail),
                    ),
                  ),
                ],
                if (remaining > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      "+$remaining sản phẩm khác",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF697487),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (order.normalizedStatus == "completed" && !isEvaluated) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4EF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      "Đơn hàng này chưa được đánh giá. Hãy để lại nhận xét sau khi sử dụng.",
                      style: TextStyle(
                        color: Color(0xFFE0563C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (order.needsRefundChat) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1EE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.support_agent_outlined,
                          color: Color(0xFFE0563C),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Đơn hàng cần liên hệ shop để xử lý hoàn tiền.",
                            style: TextStyle(
                              color: Color(0xFF6B2D21),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onOpenSupportChat,
                          child: const Text("Chat"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      "${order.orderDetails.length} sản phẩm",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF697487),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      order.total.toVnd(),
                      style: const TextStyle(
                        color: Color(0xFFE0563C),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: onOpenDetail,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF253041),
                      ),
                      child: const Text("Chi tiết"),
                    ),
                    if (_buildPrimaryAction(context) != null)
                      _buildPrimaryAction(context)!,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildPrimaryAction(BuildContext context) {
    switch (order.normalizedStatus) {
      case "pending":
        if (onCancelOrder == null) return null;
        return FilledButton.tonal(
          onPressed: isCancelling ? null : () => onCancelOrder!(order),
          child: Text(
            isCancelling ? "Đang xử lý..." : "Hủy đơn",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      case "shipping":
        if (onConfirmReceived == null) return null;
        return FilledButton(
          onPressed: isConfirming ? null : () => onConfirmReceived!(order),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
          ),
          child: Text(
            isConfirming ? "Đang xử lý..." : "Đã nhận hàng",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      case "completed":
        if (isEvaluated && onViewEvaluate != null) {
          return OutlinedButton.icon(
            onPressed: isEvaluating ? null : () => onViewEvaluate!(order),
            icon: const Icon(Icons.rate_review_outlined),
            label: Text(
              isEvaluating ? "Đang xử lý..." : "Xem đánh giá",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }
        if (!isEvaluated && onCreateEvaluate != null) {
          return OutlinedButton.icon(
            onPressed: isEvaluating ? null : () => onCreateEvaluate!(order),
            icon: const Icon(Icons.star_outline),
            label: Text(
              isEvaluating ? "Đang xử lý..." : "Đánh giá",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }
        return null;
      default:
        return null;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "--/--/----";
    final dd = date.day.toString().padLeft(2, "0");
    final mm = date.month.toString().padLeft(2, "0");
    final yyyy = date.year.toString();
    final hh = date.hour.toString().padLeft(2, "0");
    final min = date.minute.toString().padLeft(2, "0");
    return "$dd/$mm/$yyyy • $hh:$min";
  }
}

class _OrderItemPreview extends StatelessWidget {
  final OrderDetailOut detail;

  const _OrderItemPreview({required this.detail});

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl(detail.imageUrl);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 72,
            height: 72,
            color: const Color(0xFFF4F5F7),
            child: imageUrl == null
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _variantText(detail),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF697487)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    "x${detail.quantity}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF697487),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    detail.price.toVnd(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF253041),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _variantText(OrderDetailOut item) {
    final parts = <String>[];
    final color = (item.colorName ?? "").trim();
    final size = (item.sizeName ?? "").trim();
    if (color.isNotEmpty) parts.add("Màu $color");
    if (size.isNotEmpty) parts.add("Size $size");
    return parts.isEmpty ? "Phân loại đang cập nhật" : parts.join(" • ");
  }

  static String? _resolveImageUrl(String? raw) {
    final value = raw?.trim() ?? "";
    if (value.isEmpty) return null;
    if (value.startsWith("http://") || value.startsWith("https://")) {
      return value;
    }
    final base = AppConstants.baseUrl.replaceAll(RegExp(r"/+$"), "");
    return "$base${value.startsWith("/") ? "" : "/"}$value";
  }
}
