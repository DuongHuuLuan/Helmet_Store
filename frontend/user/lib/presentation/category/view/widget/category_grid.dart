import 'package:flutter/material.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/category/category.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/theme/colors.dart';

class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final int? selectedCategoryId;
  final VoidCallback onSelectAll;
  final void Function(Category c) onSelectCategory;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelectAll,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (categories.isEmpty) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final items = <_CatItem>[
      _CatItem(id: null, name: "Tất cả"),
      ...categories.map((e) => _CatItem(id: e.id, name: e.name)),
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = item.id == selectedCategoryId;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              if (item.id == null) {
                onSelectAll();
              } else {
                final c = categories.firstWhere((e) => e.id == item.id);
                onSelectCategory(c);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.secondary : colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : AppColors.primary.withOpacity(0.14),
                  width: 1,
                ),
              ),
              child: Text(
                item.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.onSecondary : colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CatItem {
  final int? id;
  final String name;
  _CatItem({required this.id, required this.name});
}
