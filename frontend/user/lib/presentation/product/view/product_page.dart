import 'dart:async';

import 'package:b2205946_duonghuuluan_luanvan/core/widgets/app_logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/view/widget/cart_drawer.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/cubit/cart_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/category/cubit/category_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/category/category.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/cubit/product_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/view/widget/product_card.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/view/widget/product_search_field.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/view/widget/product_sections.dart';

class ProductPage extends StatefulWidget {
  final String initialKeyword;

  const ProductPage({super.key, this.initialKeyword = ''});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final ScrollController _scrollController = ScrollController();
  static const double _loadMoreThreshold = 300;
  static const int _perPage = 8;
  static const Duration _debounceDuration = Duration(milliseconds: 400);

  late final TextEditingController _searchController;
  Timer? _searchDebounce;
  String _keyword = '';

  String? get _effectiveKeyword => _keyword.isEmpty ? null : _keyword;

  @override
  void initState() {
    super.initState();
    _keyword = widget.initialKeyword.trim();
    _searchController = TextEditingController(text: _keyword);
    _scrollController.addListener(_onScroll);
    Future.microtask(() async {
      await context.read<CategoryCubit>().load();
      await _reloadProducts();
    });
  }

  @override
  void didUpdateWidget(covariant ProductPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextKeyword = widget.initialKeyword.trim();
    if (oldWidget.initialKeyword == widget.initialKeyword ||
        nextKeyword == _keyword) {
      return;
    }

    _keyword = nextKeyword;
    _searchController.value = TextEditingValue(
      text: nextKeyword,
      selection: TextSelection.collapsed(offset: nextKeyword.length),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reloadProducts();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      context.read<ProductCubit>().loadMoreProducts();
    }
  }

  Future<void> _reloadProducts() {
    return context.read<ProductCubit>().loadInitialPaged(
      perPage: _perPage,
      keyword: _effectiveKeyword,
    );
  }

  void _onSearchChanged(String value) {
    final nextKeyword = value.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_debounceDuration, () {
      if (!mounted || nextKeyword == _keyword) return;
      setState(() {
        _keyword = nextKeyword;
      });
      _reloadProducts();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryState = context.watch<CategoryCubit>().state;
    final productVm = context.watch<ProductCubit>().state;
    final productCubit = context.read<ProductCubit>();
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final List<Category> categories = categoryState.categories;
    final List<Product> products = productVm.products;
    final bool isSearching = _keyword.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        title: Text(
          "Sản phẩm",
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go("/");
            }
          },
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
        ),
      ),
      body: RefreshIndicator(
        color: colorScheme.primary,
        onRefresh: _reloadProducts,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
          children: [
            ProductSearchField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              hintText: "Tìm kiếm sản phẩm",
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isSearching ? 'kết quả cho "$_keyword"' : "Tất cả sản phẩm",
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (productVm.isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: AppLogoLoader(size: 20, strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (productVm.errorMessage != null && products.isEmpty)
              _buildEmptyState(
                message: productVm.errorMessage!,
                color: colorScheme.error,
              )
            else if (!productVm.isLoading && products.isEmpty)
              _buildEmptyState(
                message: isSearching
                    ? "Không tìm thấy sản phẩm phù hợp"
                    : "Chưa có sản phẩm nào",
                color: colorScheme.onSurfaceVariant,
              )
            else if (isSearching)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 350,
                ),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    onTap: () => context.go("/products/${product.id}"),
                    onAddToCart: (product, productDetail, quantity) async {
                      await context.read<CartCubit>().addToCart(
                        productDetailId: productDetail.id,
                        quantity: quantity,
                      );
                      await CartDrawer.show(
                        context,
                        productDetailId: productDetail.id,
                      );
                    },
                  );
                },
              )
            else
              ProductSections(categories: categories, products: products),
            if (productCubit.isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppLogoLoader(size: 64, strokeWidth: 3.5),
                      SizedBox(height: 8),
                      Text("Đang tải"),
                    ],
                  ),
                ),
              )
            else if (!productCubit.hasMore && products.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Text("Đã tải hết sản phẩm")),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required String message, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: color),
        ),
      ),
    );
  }
}
