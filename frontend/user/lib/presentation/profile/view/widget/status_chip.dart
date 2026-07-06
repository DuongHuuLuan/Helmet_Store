import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = _labelForStatus(status);
    final color = _colorForStatus(status, colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _labelForStatus(String value) {
    switch (value) {
      case "pending":
        return "Chờ xác nhận";
      case "shipping":
        return "Đang giao hàng";
      case "completed":
        return "Đã hoàn tất";
      case "cancelled":
        return "Đã hủy";
      default:
        return value;
    }
  }

  Color _colorForStatus(String value, ColorScheme scheme) {
    switch (value) {
      case "pending":
        return Colors.orange.shade700;
      case "shipping":
        return scheme.secondary;
      case "completed":
        return Colors.green.shade700;
      case "cancelled":
        return Colors.red.shade700;
      default:
        return scheme.secondary;
    }
  }
}
