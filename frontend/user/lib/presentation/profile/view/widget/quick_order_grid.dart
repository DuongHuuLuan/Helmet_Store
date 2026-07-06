import 'package:flutter/material.dart';

class QuickOrderItem {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  const QuickOrderItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
  });
}

class QuickOrderGrid extends StatelessWidget {
  final List<QuickOrderItem> items;

  const QuickOrderGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map((item) => Expanded(child: _QuickOrderShortcut(item: item)))
          .toList(),
    );
  }
}

class _QuickOrderShortcut extends StatelessWidget {
  final QuickOrderItem item;

  const _QuickOrderShortcut({required this.item});

  @override
  Widget build(BuildContext context) {
    final badge = item.count > 99 ? "99+" : "${item.count}";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    item.icon,
                    color: item.color,
                    size: 28, // kích thước icon
                  ),
                  if (item.count > 0)
                    Positioned(
                      right: -10, //vị trí badge
                      top: -8,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          badge,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
