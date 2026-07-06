import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message_payload.dart';
import 'package:flutter/material.dart';

class ChatVariantPicker extends StatelessWidget {
  final List<ChatProductVariantData> variants;
  final int? selectedProductDetailId;
  final ValueChanged<ChatProductVariantData>? onVariantTap;

  const ChatVariantPicker({
    super.key,
    required this.variants,
    this.selectedProductDetailId,
    this.onVariantTap,
  });

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: variants.map((variant) {
        final colorName = (variant.colorName ?? "").trim();
        final sizeName = (variant.sizeName ?? "").trim();
        final labelParts = <String>[
          if (colorName.isNotEmpty) colorName,
          if (sizeName.isNotEmpty) sizeName,
        ];
        final label = labelParts.isEmpty ? "Biến thể" : labelParts.join(" - ");
        final isSelected = selectedProductDetailId == variant.productDetailId;
        final stockLabel = variant.isAvailable
            ? "Còn ${variant.stock}"
            : "Hết hàng";

        return InkWell(
          onTap: onVariantTap == null || !variant.isAvailable
              ? null
              : () => onVariantTap!(variant),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: !variant.isAvailable
                  ? scheme.surfaceContainerHighest
                  : isSelected
                  ? scheme.primaryContainer
                  : scheme.primaryContainer.withOpacity(0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? scheme.primary
                    : variant.isAvailable
                    ? scheme.primary.withOpacity(0.18)
                    : scheme.outline.withOpacity(0.18),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: variant.isAvailable
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stockLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: variant.isAvailable
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
