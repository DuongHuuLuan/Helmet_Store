import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/delivery_info.dart';
import 'package:flutter/material.dart';

class AddressSection extends StatelessWidget {
  final List<DeliveryInfo> deliveries;
  final DeliveryInfo? selected;
  final bool useSaved;
  final ValueChanged<DeliveryInfo?> onSelect;
  final VoidCallback onUseNew;

  const AddressSection({
    super.key,
    required this.deliveries,
    required this.onSelect,
    required this.onUseNew,
    required this.selected,
    required this.useSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (deliveries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              "Bạn chưa có địa chỉ đã lưu. Hãy nhập địa chỉ giao hàng mới để tiếp tục.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ...deliveries.map(
          (info) => _AddressOptionCard(
            icon: Icons.location_on_outlined,
            title: "${info.name} • ${info.phone}",
            subtitle: info.address,
            isSelected: useSaved && selected?.id == info.id,
            onTap: () => onSelect(info),
          ),
        ),
        _AddressOptionCard(
          icon: Icons.add_location_alt_outlined,
          title: "Thêm địa chỉ giao hàng mới",
          subtitle: deliveries.isEmpty
              ? "Nhập địa chỉ đầu tiên cho đơn hàng này rồi bấm Lưu địa chỉ mới."
              : "Mở form bên dưới để nhập địa chỉ mới và bấm Lưu địa chỉ mới, hoặc hệ thống sẽ tự động lưu khi bạn đặt hàng thành công.",
          isSelected: !useSaved,
          onTap: onUseNew,
        ),
      ],
    );
  }
}

class _AddressOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected
              ? colorScheme.secondary
              : colorScheme.outlineVariant,
          width: isSelected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.secondary.withValues(alpha: 0.12)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.secondary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _SelectionIndicator(isSelected: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  final bool isSelected;

  const _SelectionIndicator({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? colorScheme.secondary : Colors.transparent,
        border: Border.all(
          color: isSelected ? colorScheme.secondary : colorScheme.outline,
        ),
      ),
      child: isSelected
          ? Icon(Icons.check, size: 14, color: colorScheme.onSecondary)
          : null,
    );
  }
}
