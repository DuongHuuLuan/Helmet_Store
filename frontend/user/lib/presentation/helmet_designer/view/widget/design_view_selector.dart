import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_image.dart';
import 'package:flutter/material.dart';

class DesignViewSelector extends StatelessWidget {
  final List<ProductImage> views;
  final String? activeViewImageKey;
  final ValueChanged<String?> onSelected;

  const DesignViewSelector({
    super.key,
    required this.views,
    required this.activeViewImageKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in views) ...[
            ChoiceChip(
              label: Text(viewImageKeyLabel(item.viewImageKey)),
              selected:
                  (item.viewImageKey ?? '').trim() ==
                  (activeViewImageKey ?? '').trim(),
              onSelected: (_) => onSelected(item.viewImageKey),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
