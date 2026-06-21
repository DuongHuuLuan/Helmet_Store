import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message_payload.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatCartActionResultBubble extends StatelessWidget {
  final ChatMessagePayload payload;

  const ChatCartActionResultBubble({super.key, required this.payload});

  ChatProductActionData? get _openCartAction {
    for (final action in payload.actions) {
      if (action.type == "open_cart") return action;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final result = payload.cartActionResult;
    if (result == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final isSuccess = result.status.trim().toLowerCase() == "success";
    final title = payload.title?.trim().isNotEmpty == true
        ? payload.title!.trim()
        : (isSuccess ? "Đã thêm vào giỏ hàng" : "Không thể thêm vào giỏ hàng");
    final summary = result.message?.trim().isNotEmpty == true
        ? result.message!.trim()
        : title;
    final imageUrl = (result.imageUrl ?? "").trim();
    final openCartAction = _openCartAction;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSuccess
                      ? scheme.primaryContainer
                      : scheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                  size: 20,
                  color: isSuccess
                      ? scheme.onPrimaryContainer
                      : scheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
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
                    const SizedBox(height: 4),
                    Text(
                      summary,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((result.productName ?? "").trim().isNotEmpty ||
              imageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
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
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              size: 22,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: scheme.surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                size: 22,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.productName?.trim().isNotEmpty == true
                              ? result.productName!
                              : "Sản phẩm",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                        ),
                        if ((result.variantLabel ?? "").trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            result.variantLabel!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                        if (result.quantity > 0) ...[
                          const SizedBox(height: 6),
                          Text(
                            "Số lượng thêm: ${result.quantity}",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isSuccess && openCartAction != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push(
                (openCartAction.target ?? "").trim().isNotEmpty
                    ? openCartAction.target!
                    : "/cart",
              ),
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              label: Text(
                openCartAction.label.trim().isNotEmpty
                    ? openCartAction.label
                    : "Xem giỏ hàng",
              ),
            ),
          ],
        ],
      ),
    );
  }
}
