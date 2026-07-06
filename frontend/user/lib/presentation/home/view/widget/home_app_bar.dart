import 'package:b2205946_duonghuuluan_luanvan/core/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/home/view/widget/circle_icon_button.dart';
import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onProfile;
  final VoidCallback onCart;
  final VoidCallback onSearch;
  final VoidCallback onMenu;
  const HomeAppBar({
    super.key,
    required this.onCart,
    required this.onMenu,
    required this.onProfile,
    required this.onSearch,
  });

  @override
  Size get preferredSize => const Size.fromHeight(82);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 30, left: 10, right: 10, bottom: 10),
      color: AppColors.primary,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                // image: AssetImage("assets/images/logo.webp"),
                image: AssetImage("assets/images/logo_royalStore2.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Spacer(),
          CircleIconButton(icon: Icons.person, onTap: onProfile),
          const SizedBox(width: 12),
          CircleIconButton(icon: Icons.shopping_bag, onTap: onCart),
          const SizedBox(width: 12),
          CircleIconButton(icon: Icons.search, onTap: onSearch),
          const SizedBox(width: 12),
          CircleIconButton(icon: Icons.menu, onTap: onMenu),
        ],
      ),
    );
  }
}
