import 'dart:async';

import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/view/widget/cart_drawer.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/cubit/cart_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/category/cubit/category_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/category/view/widget/category_grid.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/cubit/product_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/view/widget/product_card.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/view/widget/product_search_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProductCatagoryPage extends StatefulWidget {
  final int? categoryId;
  final String initialKeyword;

  const ProductCatagoryPage({
    super.key,
    this.categoryId,
    this.initialKeyword = '',
  });

  @override
  State<ProductCatagoryPage> createState() => _ProductCatagoryPageState();
}

class _ProductCatagoryPageState extends State<ProductCatagoryPage> {
  final ScrollController _scrollController = ScrollController();
  static const double _loadMoreThreshold = 300;
  static const int _perPage = 8;
  static const Duration _debounceDuration = Duration(milliseconds: 400);

  int? _selectedCategoryId;
  late final TextEditingController _searchController;
  Timer? _searchDebounce;
  String _keyword = '';

  String? get _effectiveKeyword => _keyword.isEmpty ? null : _keyword;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _keyword = widget.initialKeyword.trim();
    _searchController = TextEditingController(text: _keyword);
    _scrollController.addListener(_onScroll);

    Future.microtask(() async {
      await context.read<CategoryCubit>().load();
      await _reloadProducts();
    });
  }

  @override
  void didUpdateWidget(covariant ProductCatagoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldReload =
        oldWidget.categoryId != widget.categoryId ||
        oldWidget.initialKeyword != widget.initialKeyword;
    if (!shouldReload) return;

    final nextKeyword = widget.initialKeyword.trim();
    _selectedCategoryId = widget.categoryId;
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
      categoryId: _selectedCategoryId,
      perPage: _perPage,
      keyword: _effectiveKeyword,
    );
  }

  Future<void> _selectCategory(int? categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    await _reloadProducts();
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
    final categoryState = context.watch<CategoryCubit>().state;
    final productVm = context.watch<ProductCubit>().state;
    final productCubit = context.read<ProductCubit>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        title: Text(
          "Danh mục sản phẩm",
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
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
          children: [
            CategoryGrid(
              categories: categoryState.categories,
              selectedCategoryId: _selectedCategoryId,
              onSelectAll: () => _selectCategory(null),
              onSelectCategory: (c) => _selectCategory(c.id),
            ),
            const SizedBox(height: 20),
            ProductSearchField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              hintText: "Tìm trong danh mục đang chọn",
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _keyword.isNotEmpty
                        ? 'kết quả cho "$_keyword"'
                        : _selectedCategoryId == null
                        ? "Tất cả sản phẩm"
                        : "Sản phẩm theo danh mục",
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.secondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (productVm.errorMessage != null && productVm.products.isEmpty)
              _buildEmptyState(
                message: productVm.errorMessage!,
                color: colorScheme.error,
              )
            else if (!productVm.isLoading && productVm.products.isEmpty)
              _buildEmptyState(
                message: _keyword.isNotEmpty
                    ? "Không tìm thấy sản phẩm phù hợp"
                    : "Không có sản phẩm nào trong danh mục này",
                color: colorScheme.onSurfaceVariant,
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: productVm.products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 340,
                ),
                itemBuilder: (context, index) {
                  final product = productVm.products[index];
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
              ),
            if (productCubit.isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text("Đang tải"),
                    ],
                  ),
                ),
              )
            else if (!productCubit.hasMore && productVm.products.isNotEmpty)
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
