import 'package:b2205946_duonghuuluan_luanvan/core/utils/currency_ext.dart';
import 'package:flutter/material.dart';

class PaymentSummary extends StatelessWidget {
  final double subtotal;
  final double discountAmount;
  final double shippingFee;
  final double total;

  const PaymentSummary({
    super.key,
    required this.subtotal,
    required this.discountAmount,
    required this.shippingFee,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final safeDiscount = discountAmount.clamp(0, subtotal).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _SummaryRow(label: "Tổng tiền hàng", value: subtotal.toVnd()),
            _SummaryRow(
              label: "Giảm giá sản phẩm",
              value: "-${safeDiscount.toVnd()}",
              valueStyle: const TextStyle(color: Colors.red),
            ),
            _SummaryRow(label: "Phí vận chuyển", value: shippingFee.toVnd()),
            const Divider(height: 18),
            _SummaryRow(
              label: "Tổng thanh toán",
              value: total.toVnd(),
              valueStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
