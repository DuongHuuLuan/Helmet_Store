import 'package:b2205946_duonghuuluan_luanvan/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_detail.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/view/widget/product_card.dart';

class CategoryProductSection extends StatefulWidget {
  final String title;
  final String? bannerPath;
  final List<Product> products;

  final VoidCallback onSeeMore;
  final void Function(Product product) onProductTap;
  final void Function(
    Product product,
    ProductDetail productDetail,
    int quantity,
  )
  onAddToCart;

  const CategoryProductSection({
    super.key,
    required this.title,
    this.bannerPath,
    required this.products,
    required this.onAddToCart,
    required this.onProductTap,
    required this.onSeeMore,
  });

  @override
  State<CategoryProductSection> createState() => _CategoryProductSectionState();
}

class _CategoryProductSectionState extends State<CategoryProductSection> {
  final ScrollController _controller = ScrollController();

  bool _showLeft = false;
  bool _showRight = false;

  void _updateArrows() {
    if (!_controller.hasClients) return;

    final max = _controller.position.maxScrollExtent;
    final offset = _controller.offset;

    final canScroll = max > 0;
    final showLeftNow = canScroll && offset > 2;
    final showRightNow = canScroll && offset < max - 2;

    if (showLeftNow != _showLeft || showRightNow != _showRight) {
      setState(() {
        _showLeft = showLeftNow;
        _showRight = showRightNow;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void didUpdateWidget(covariant CategoryProductSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.products.length != widget.products.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateArrows);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      margin: const EdgeInsets.only(bottom: 15),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: widget.bannerPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            widget.bannerPath!,
                            height: 80,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                thickness: 1,
                                color: Color(0xFFE0E0E0),
                                endIndent: 16, // Khoảng cách giữa gạch và chữ
                              ),
                            ),

                            Text(
                              widget.title.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSecondary,
                                letterSpacing: 1,
                              ),
                            ),

                            const Expanded(
                              child: Divider(
                                thickness: 1,
                                color: Color(0xFFE0E0E0),
                                indent: 16, // Khoảng cách giữa chữ và gạch
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: widget.products.length > 4 ? 4 : widget.products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.52,
            ),
            itemBuilder: (context, index) {
              final product = widget.products[index];
              return ProductCard(
                product: product,
                onTap: () => widget.onProductTap(product),
                onAddToCart: (p, v, quantity) =>
                    widget.onAddToCart(p, v, quantity),
              );
            },
          ),

          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: widget.onSeeMore,
                  child: Text(
                    "Xem thêm",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300),
                  ),
                ),
                const SizedBox(width: 5),
                IconButton(
                  onPressed: widget.onSeeMore,
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.secondary,
                  ),
                  icon: Icon(Icons.chevron_right, color: AppColors.onPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
