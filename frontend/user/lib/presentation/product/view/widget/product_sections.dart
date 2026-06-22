import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/cubit/cart_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/view/widget/cart_drawer.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/category/category.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_detail.dart';

import 'category_product_section.dart';

class ProductSections extends StatelessWidget {
  final List<Category> categories;
  final List<Product> products;

  const ProductSections({
    super.key,
    required this.categories,
    required this.products,
  });

  String? _getBannerPath(Category category) {
    switch (category.name.trim().toLowerCase()) {
      case 'mũ bảo hiểm 1/2':
        return 'assets/images/1-2.webp';
      case 'mũ bảo hiểm 3/4':
        return 'assets/images/3-4.webp';
      case 'mũ fullface':
        return 'assets/images/fullface.webp';
      case 'mũ lật hàm':
        return 'assets/images/lat_ham.png';
      case 'mũ trẻ em':
        return 'assets/images/tre-em.png';
      case 'mũ xe đạp':
        return 'assets/images/xe-dap.png';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<int, List<Product>> byCategory = HashMap();
    for (final p in products) {
      byCategory.putIfAbsent(p.categoryId, () => []).add(p);
    }

    return Column(
      children: categories.map((c) {
        final items = byCategory[c.id] ?? const <Product>[];
        if (items.isEmpty) return const SizedBox.shrink();

        return CategoryProductSection(
          title: c.name.toUpperCase(),
          bannerPath: _getBannerPath(c),
          products: items,
          onSeeMore: () => context.go('/products/categories/${c.id}'),
          onProductTap: (p) => context.go('/products/${p.id}'),
          onAddToCart: (Product p, ProductDetail v, int quantity) async {
            await context.read<CartCubit>().addToCart(
              productDetailId: v.id,
              quantity: quantity,
            );
            await CartDrawer.show(context, productDetailId: v.id);
          },
        );
      }).toList(),
    );
  }
}
