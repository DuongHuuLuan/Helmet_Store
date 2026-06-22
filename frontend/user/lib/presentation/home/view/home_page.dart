import 'dart:ui';
import 'package:b2205946_duonghuuluan_luanvan/core/widgets/app_logo_loader.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/home/view/widget/home_category_image_grid.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/home/view/widget/product_promo_carousel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/cubit/cart_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/category/cubit/category_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/home/view/widget/circle_icon_button.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/home/view/widget/hero_carousel.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/home/view/widget/home_drawer.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/cubit/product_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/view/widget/product_sections.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<ProductCubit>().getAllProduct();
      await context.read<CategoryCubit>().load();
      final cartVm = context.read<CartCubit>();
      if (cartVm.state.cart == null && !cartVm.state.isLoading) {
        await cartVm.fetchCart();
      }
    });
  }

  void _openCategory(BuildContext context, int categoryId) {
    context.go('/products/categories/$categoryId');
  }

  void _openProduct(BuildContext context, int productId) {
    context.go('/products/$productId');
  }

  @override
  Widget build(BuildContext context) {
    final productVm = context.watch<ProductCubit>().state;
    final categoryVm = context.watch<CategoryCubit>().state;
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const HomeDrawer(),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _HomeSliverAppBar(
            onCart: () => context.go("/cart"),
            onSearch: () => context.go("/products"),
            onProfile: () => context.go("/profile"),
            onMenu: () => _scaffoldKey.currentState?.openDrawer(),
          ),

          const SliverToBoxAdapter(
            child: HeroCarousel(
              imageUrls: [
                "assets/images/banner1.webp",
                "assets/images/banner2.webp",
                "assets/images/banner3.webp",
                "assets/images/banner4.webp",
              ],
              height: 300,
            ),
          ),

          // SliverToBoxAdapter(
          //   child: CategoryStrip(
          //     categories: categoryVm.categories,
          //     thumbnails: categoryThumbs,
          //     onTap: (c) => context.go("/products/categories/${c.id}"),
          //   ),
          // ),
          SliverToBoxAdapter(
            child: ProductPromoCarousel(
              height: 170,
              onProductTap: (productId) => _openProduct(context, productId),
              items: [
                ProductPromoItem(
                  imagePath: 'assets/images/M139h.webp',
                  productId: 7,
                ),
                ProductPromoItem(
                  imagePath: 'assets/images/M239-1.webp',
                  productId: 24,
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: HomeCategoryImageGrid(
              backgroundImage: 'assets/images/bg.webp',
              onCategoryTap: (categoryId) => _openCategory(context, categoryId),
              items: [
                HomeCategoryImageItem(
                  title: 'MŨ BẢO HIỂM 1/2',
                  image: 'assets/images/MBH_1_2.webp',
                  categoryId: 1,
                ),
                HomeCategoryImageItem(
                  title: 'MŨ BẢO HIỂM 3/4',
                  image: 'assets/images/MBH_3_4.webp',
                  categoryId: 2,
                ),
                HomeCategoryImageItem(
                  title: 'MŨ BẢO HIỂM FULLFACE',
                  image: 'assets/images/MBH_fullface.webp',
                  categoryId: 3,
                ),
                HomeCategoryImageItem(
                  title: 'MŨ BẢO HIỂM TRẺ EM',
                  image: 'assets/images/MBH_KID.webp',
                  categoryId: 5,
                ),
              ],
            ),
          ),

          if (productVm.isLoading && productVm.products.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: AppLogoLoader(size: 64, strokeWidth: 3.5)),
              ),
            )
          else if (productVm.errorMessage != null && productVm.products.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  productVm.errorMessage!,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: ProductSections(
                categories: categoryVm.categories,
                products: productVm.products,
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeSliverAppBar extends StatelessWidget {
  final VoidCallback onProfile;
  final VoidCallback onCart;
  final VoidCallback onSearch;
  final VoidCallback onMenu;

  const _HomeSliverAppBar({
    required this.onProfile,
    required this.onCart,
    required this.onSearch,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);

    final statusBarH = media.padding.top;
    final w = media.size.width;
    final double logoMax = (w * 0.14).clamp(48.0, 58.0);
    final double logoMin = (w * 0.115).clamp(40.0, 48.0);
    final double topPadMax = (w * 0.030).clamp(8.0, 16.0);
    final double topPadMin = 0.0;
    final double bottomPadMax = (w * 0.020).clamp(6.0, 12.0);
    final double expandedH = statusBarH + logoMax + topPadMax + bottomPadMax;
    final double collapsedH = statusBarH + logoMin + topPadMin;

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.primary,
      expandedHeight: expandedH,
      collapsedHeight: collapsedH,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final t =
              ((constraints.maxHeight - collapsedH) / (expandedH - collapsedH))
                  .clamp(0.0, 1.0);
          final logoSize = lerpDouble(logoMin, logoMax, t)!;
          final topPad = lerpDouble(topPadMin, topPadMax, t)!;
          final bottomPad = lerpDouble(0.0, bottomPadMax, t)!;

          return Container(
            color: colorScheme.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(
                  top: topPad,
                  left: 10,
                  right: 10,
                  bottom: bottomPad,
                ),
                child: Row(
                  children: [
                    // Logo
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage(
                            "assets/images/logo_royalStore2.png",
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const Spacer(),
                    CircleIconButton(icon: Icons.person, onTap: onProfile),
                    const SizedBox(width: 8),
                    _HomeCartAction(onTap: onCart),
                    const SizedBox(width: 8),
                    CircleIconButton(icon: Icons.search, onTap: onSearch),
                    const SizedBox(width: 8),
                    CircleIconButton(icon: Icons.menu, onTap: onMenu),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeCartAction extends StatelessWidget {
  final VoidCallback onTap;

  const _HomeCartAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartCubit, int>((c) => c.cartBadgeCount);
    return CircleIconButton(
      icon: Icons.shopping_cart_outlined,
      onTap: onTap,
      badgeCount: count,
    );
  }
}
