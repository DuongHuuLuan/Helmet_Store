import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/ghn_models.dart';
import 'package:flutter/material.dart';

class ShippingSection extends StatelessWidget {
  final List<GhnServiceOption> services;
  final GhnServiceOption? selected;
  final double? fee;
  final ValueChanged<GhnServiceOption?> onSelect;

  const ShippingSection({
    super.key,
    required this.services,
    required this.selected,
    required this.fee,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (services.isEmpty) {
      return const Text("Vui lòng chọn địa chỉ để xem dịch vụ GHN");
    }
    return Column(
      children: services
          .map(
            (service) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text(service.shortName),
                subtitle: Text("Dịch vụ ${service.serviceId}"),
                trailing: Radio<GhnServiceOption>(
                  value: service,
                  groupValue: selected,
                  onChanged: onSelect,
                  activeColor: colorScheme.secondary,
                ),
                onTap: () => onSelect(service),
              ),
            ),
          )
          .toList(),
    );
  }
}
