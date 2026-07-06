import 'package:b2205946_duonghuuluan_luanvan/core/utils/currency_ext.dart';
import 'package:flutter/material.dart';

class CartSummary extends StatelessWidget {
  final double total;
  final double discountAmount;
  final int appliedDiscountCount;

  const CartSummary({
    super.key,
    required this.total,
    this.discountAmount = 0,
    this.appliedDiscountCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final safeDiscount = discountAmount.clamp(0, total).toDouble();
    final finalTotal = total - safeDiscount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "TỔNG CỘNG GIỎ HÀNG",
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Divider(height: 20, color: colorScheme.outlineVariant),
          _SummaryRow(
            label: "Tạm tính",
            value: total.toVnd(),
            colorScheme: colorScheme,
          ),
          if (safeDiscount > 0) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: appliedDiscountCount > 0
                  ? "Giảm giá ($appliedDiscountCount mã)"
                  : "Giảm giá",
              value: "- ${safeDiscount.toVnd()}",
              customValueColor: Colors.red,
              colorScheme: colorScheme,
            ),
          ],
          Divider(height: 18, color: colorScheme.outlineVariant),
          _SummaryRow(
            label: "Tổng",
            value: finalTotal.toVnd(),
            isTotal: true,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final ColorScheme colorScheme;
  final Color? customValueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    required this.colorScheme,
    this.customValueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 16 : 14,
            color:
                customValueColor ??
                (isTotal ? colorScheme.onSurface : colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}
