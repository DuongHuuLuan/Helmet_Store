import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/payment_method.dart';
import 'package:flutter/material.dart';

class PaymentSection extends StatelessWidget {
  final List<PaymentMethod> methods;
  final PaymentMethod? selected;
  final ValueChanged<PaymentMethod?> onSelect;

  const PaymentSection({
    super.key,
    required this.methods,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (methods.isEmpty) {
      return const Text("Chưa có phương thức thanh toán");
    }
    return Column(
      children: methods
          .map(
            (method) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: Text(method.name),
                trailing: Radio<PaymentMethod>(
                  value: method,
                  groupValue: selected,
                  onChanged: onSelect,
                  activeColor: colorScheme.secondary,
                ),
                onTap: () => onSelect(method),
              ),
            ),
          )
          .toList(),
    );
  }
}
