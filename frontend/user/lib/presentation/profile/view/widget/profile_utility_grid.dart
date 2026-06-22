import 'package:flutter/material.dart';

class ProfileUtilityItem {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final VoidCallback? onTap;

  const ProfileUtilityItem({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.onTap,
  });
}

class ProfileUtilityGrid extends StatelessWidget {
  final List<ProfileUtilityItem> items;

  const ProfileUtilityGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 340;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: isCompact ? 100 : 80,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE9EBF0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      top: 10,
                      right: 16,
                      bottom: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(item.icon, color: Colors.black45, size: 26),
                            const Spacer(),
                            if ((item.badgeText ?? "").trim().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F2F6),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  item.badgeText!,
                                  style: const TextStyle(
                                    color: Color(0xFF2D3436),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            else
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFFB7BEC8),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2D3436),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFF657184),
                                height: 1.2,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
