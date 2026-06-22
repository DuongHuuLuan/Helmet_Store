import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message_payload.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/chat/view/widget/chat_product_card.dart';
import 'package:flutter/material.dart';

class ChatProductListBubble extends StatelessWidget {
  final ChatMessagePayload payload;

  const ChatProductListBubble({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    if (payload.kind != "product_list" || payload.products.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((payload.title ?? "").trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              payload.title!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
        ...payload.products.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == payload.products.length - 1 ? 0 : 12,
            ),
            child: ChatProductCard(product: product),
          );
        }),
        if (payload.followUpSuggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            "Gợi ý tiếp theo",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: payload.followUpSuggestions.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
