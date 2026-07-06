import 'package:b2205946_duonghuuluan_luanvan/core/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message_payload.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ChatOrderSummaryBubble extends StatelessWidget {
  final ChatMessagePayload payload;

  const ChatOrderSummaryBubble({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final order = payload.order;
    if (order == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final title = payload.title?.trim().isNotEmpty == true
        ? payload.title!.trim()
        : "Đơn hàng #${order.orderId}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          _MetaRow(
            label: "Trạng thái",
            value: order.statusLabel ?? order.status,
          ),
          _MetaRow(
            label: "Thanh toán",
            value: order.paymentStatusLabel ?? order.paymentStatus,
          ),
          if ((order.paymentMethodName ?? "").trim().isNotEmpty)
            _MetaRow(label: "Phương thức", value: order.paymentMethodName!),
          _MetaRow(label: "Tổng số lượng", value: "${order.totalItems}"),
          _MetaRow(label: "Tổng tiền", value: order.totalAmount.toVnd()),
          if (order.shippingFee > 0)
            _MetaRow(label: "Phí vận chuyển", value: order.shippingFee.toVnd()),
          if ((order.deliveryAddress ?? "").trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Địa chỉ giao hàng",
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              order.deliveryAddress!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              "Sản phẩm",
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OrderItemTile(item: item),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 98,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final ChatOrderItemData item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = (item.imageUrl ?? "").trim();
    final variantBits = [
      if ((item.colorName ?? "").trim().isNotEmpty) item.colorName!,
      if ((item.sizeName ?? "").trim().isNotEmpty) item.sizeName!,
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl.isEmpty
                ? Container(
                    width: 56,
                    height: 56,
                    color: scheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const Icon(Icons.inventory_2_outlined, size: 22),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: scheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined, size: 22),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                if (variantBits.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    variantBits.join(" / "),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  "SL ${item.quantity} / ${item.unitPrice.toVnd()}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
