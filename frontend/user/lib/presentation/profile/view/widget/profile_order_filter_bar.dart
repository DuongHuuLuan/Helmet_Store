import 'package:flutter/material.dart';

class ProfileOrderFilterOption {
  final String key;
  final String label;
  final int count;

  const ProfileOrderFilterOption({
    required this.key,
    required this.label,
    required this.count,
  });
}

class ProfileOrderFilterBar extends StatelessWidget {
  final List<ProfileOrderFilterOption> items;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  const ProfileOrderFilterBar({
    super.key,
    required this.items,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: items
              .map(
                (item) => _FilterButton(
                  item: item,
                  isSelected: item.key == selectedKey,
                  onTap: () => onSelected(item.key),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final ProfileOrderFilterOption item;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFFF2593A);
    final textColor = isSelected ? activeColor : const Color(0xFF253041);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? activeColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              if (item.count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.12)
                        : const Color(0xFFF1F3F6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.count > 99 ? "99+" : "${item.count}",
                    style: TextStyle(
                      color: isSelected ? activeColor : const Color(0xFF6C7687),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
