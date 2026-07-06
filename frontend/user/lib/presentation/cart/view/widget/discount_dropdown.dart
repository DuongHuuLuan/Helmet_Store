import 'package:b2205946_duonghuuluan_luanvan/domain/entity/discount/discount.dart';
import 'package:flutter/material.dart';

class DiscountDropdown extends StatelessWidget {
  final List<Discount> discounts;
  final bool isLoading;
  final Set<int> selectedIds;
  final void Function(Discount discount, bool selected) onToggle;

  const DiscountDropdown({
    super.key,
    required this.discounts,
    required this.isLoading,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final divider = Theme.of(context).dividerColor;
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    final iconColor = Theme.of(context).textTheme.bodySmall?.color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text("Mã giảm giá", style: titleStyle),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Bạn có thể chọn nhiều mã, nhưng chỉ 1 mã cho mỗi danh mục.",
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const Text("Đang tải mã giảm giá...")
          else if (discounts.isEmpty)
            const Text("Không có mã giảm giá hợp lệ cho các sản phẩm đã chọn.")
          else
            Column(
              children: discounts
                  .map(
                    (d) => CheckboxListTile(
                      value: selectedIds.contains(d.id),
                      onChanged: (value) => onToggle(d, value ?? false),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text("${d.name} - ${d.percent}%"),
                      subtitle: d.description.isEmpty
                          ? Text("Danh mục #${d.categoryId}")
                          : Text(d.description),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
