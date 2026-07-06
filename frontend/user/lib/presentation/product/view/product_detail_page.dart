import 'dart:math';
import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/theme/colors.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:b2205946_duonghuuluan_luanvan/core/widgets/app_logo_loader.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/view/widget/arrow_button.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:b2205946_duonghuuluan_luanvan/injection_container.dart' as di;
import 'package:b2205946_duonghuuluan_luanvan/core/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/view/widget/cart_drawer.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/evaluate/evaluate.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_detail.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_extension.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_image.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/evaluate/get_product_evaluates_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/product/get_products_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/cubit/cart_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/cubit/product_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/view/widget/category_product_section.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;
  final void Function(Product product, ProductDetail productDetail, int qty)?
  onAddToCart;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.onAddToCart,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  static const int _relatedProductsPerPage = 12;
  static const int _relatedProductsDisplayLimit = 6;

  ProductEvaluatePage? _evaluatePreview;
  List<Product> _relatedProducts = const [];
  bool _isPageLoading = true;
  bool _isEvaluateLoading = false;
  bool _isRelatedProductsLoading = false;
  String? _evaluateError;
  String? _relatedProductsError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadPageData);
  }

  @override
  void didUpdateWidget(covariant ProductDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId == widget.productId) return;
    Future.microtask(_loadPageData);
  }

  Future<void> _loadPageData() async {
    if (!mounted) return;
    setState(() {
      _isPageLoading = true;
      _evaluatePreview = null;
      _evaluateError = null;
      _isEvaluateLoading = false;
      _relatedProducts = const [];
      _relatedProductsError = null;
      _isRelatedProductsLoading = false;
    });

    final cartCubit = context.read<CartCubit>();
    if (cartCubit.state.cart == null && !cartCubit.state.isLoading) {
      cartCubit.fetchCart();
    }

    final vm = context.read<ProductCubit>();
    await Future.wait<void>([
      vm.productDetail(widget.productId),
      _loadEvaluatePreview(),
    ]);

    if (!mounted) return;

    final currentProduct = vm.state.product;
    if (currentProduct != null && currentProduct.id == widget.productId) {
      await _loadRelatedProducts(currentProduct);
    }

    if (!mounted) return;
    setState(() {
      _isPageLoading = false;
    });
  }

  Future<Either<Failure, ProductEvaluatePage>> _fetchProductEvaluates({
    int page = 1,
    int perPage = 3,
  }) {
    return di.getIt<GetProductEvaluatesUseCase>()(
      productId: widget.productId,
      page: page,
      perPage: perPage,
    );
  }

  Future<void> _loadEvaluatePreview() async {
    final requestProductId = widget.productId;
    if (!mounted) return;
    setState(() {
      _isEvaluateLoading = true;
      _evaluateError = null;
    });

    final result = await di.getIt<GetProductEvaluatesUseCase>()(
      productId: requestProductId,
      perPage: 3,
    );
    result.fold(
      (failure) {
        if (!mounted || widget.productId != requestProductId) return;
        setState(() {
          _evaluateError = failure.message;
        });
      },
      (page) {
        if (!mounted || widget.productId != requestProductId) return;
        setState(() {
          _evaluatePreview = page;
        });
      },
    );
    if (!mounted || widget.productId != requestProductId) return;
    setState(() {
      _isEvaluateLoading = false;
    });
  }

  Future<void> _loadRelatedProducts(Product product) async {
    final requestProductId = product.id;
    setState(() {
      _isRelatedProductsLoading = true;
      _relatedProductsError = null;
    });

    final result = await di.getIt<GetProductsUseCase>()(
      categoryId: product.categoryId,
      page: 1,
      perPage: _relatedProductsPerPage,
    );
    result.fold(
      (failure) {
        if (!mounted || widget.productId != requestProductId) return;
        setState(() {
          _relatedProducts = const [];
          _relatedProductsError = failure.message;
        });
      },
      (items) {
        if (!mounted || widget.productId != requestProductId) return;
        final related = items
            .where(
              (item) =>
                  item.id != requestProductId &&
                  item.categoryId == product.categoryId &&
                  item.productDetails.any((detail) => detail.isActive),
            )
            .take(_relatedProductsDisplayLimit)
            .toList(growable: false);
        setState(() {
          _relatedProducts = related;
        });
      },
    );
    if (mounted) {
      setState(() {
        _isRelatedProductsLoading = false;
      });
    }
  }

  void _openHelmetDesigner(
    Product product,
    String? baseImageUrl,
    ProductDetail productDetail,
    int quantity,
  ) {
    final designViews = product.filterDesignViews(productDetail.colorId);
    context.push(
      "/helmet-designer",
      extra: {
        "helmetProductId": product.id,
        "productDetailId": productDetail.id,
        "quantity": quantity,
        "helmetName": product.name,
        "helmetBaseImageUrl": baseImageUrl ?? "",
        "helmetDesignViews": designViews,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<ProductCubit>().state;
    final productCubit = context.read<ProductCubit>();
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final hasCurrentProduct = vm.product?.id == widget.productId;

    // Trạng thái Loading
    if ((_isPageLoading || vm.isLoading) && !hasCurrentProduct) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: AppLogoLoader(size: 80, strokeWidth: 4)),
      );
    }

    // Trạng thái Lỗi
    if (vm.errorMessage != null && !hasCurrentProduct) {
      return Scaffold(
        appBar: AppBar(title: const Text("Chi tiết sản phẩm")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(vm.errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadPageData,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Thử lại"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!hasCurrentProduct || vm.product == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: AppLogoLoader(size: 80, strokeWidth: 4)),
      );
    }

    final Product p = vm.product!;
    final productDetail = productCubit.selectedProductDetail;
    final productImages = productCubit.displayProductImages;
    final availableQuantity = productCubit.availableQuantity;
    final canAdjustQuantity =
        !productCubit.isStockLoading &&
        availableQuantity != null &&
        availableQuantity > 0;

    final mainUrl = productImages.isNotEmpty
        ? productImages[productCubit.imgIndex.clamp(0, max(0, productImages.length - 1))]
              .url
        : null;

    final priceText = (productDetail?.price ?? 0).toVnd();
    final hasResolvedStock = availableQuantity != null;
    final isInactive = productDetail != null && !productDetail.isActive;
    final isOutOfStock =
        !isInactive && hasResolvedStock && (availableQuantity) <= 0;
    final canAddToCart =
        productDetail != null &&
        productDetail.isActive &&
        !productCubit.isStockLoading &&
        !isOutOfStock;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              title: Text(
                p.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/'),
              ),
              actions: [_ProductCartAction(), SizedBox(width: 8)],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: _ProductImageGallery(
                            images: productImages,
                            selectedColorId: productCubit.selectedColorId,
                            colorScheme: colorScheme,
                            onPageChanged: productCubit.setImgIndex,
                          ),
                        ),
                        if (productImages.length > 1) ...[
                          const SizedBox(height: 14),
                          _GalleryProgressIndicator(
                            itemCount: productImages.length,
                            activeIndex: productCubit.imgIndex,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),

                  // Danh sách màu sắc (Thumbnails)
                  if (productCubit.colors.isNotEmpty)
                    _buildSectionTitle("Chọn màu sắc", textTheme, colorScheme),

                  if (productCubit.colors.isNotEmpty)
                    Container(
                      height: 70,
                      margin: const EdgeInsets.only(top: 8),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: productCubit.colors.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final c = productCubit.colors[i];
                          final active = c.colorId == productCubit.selectedColorId;
                          final thumbUrl = _thumbForColor(
                            product: p,
                            colorId: c.colorId,
                          );

                          return InkWell(
                            onTap: () => productCubit.selectColor(c.colorId),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: active
                                      ? colorScheme.secondary
                                      : colorScheme.outlineVariant,
                                  width: active ? 2.5 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: thumbUrl == null
                                  ? Icon(
                                      Icons.image,
                                      color: colorScheme.outline,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: thumbUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.0,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Icon(
                                            Icons.image_not_supported_outlined,
                                            color: colorScheme.outline,
                                          ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Tên và Giá
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          priceText,
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (isInactive || isOutOfStock)
                          Align(
                            alignment:
                                Alignment.centerLeft, // Căn lề trái cho nhãn
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isInactive
                                    ? Colors.grey.shade300
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                isInactive ? "Ngừng bán" : "Hết hàng",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isInactive
                                      ? Colors.grey.shade800
                                      : Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Chọn Size
                  if (productCubit.sizes.isNotEmpty)
                    _buildSectionTitle("Kích thước", textTheme, colorScheme),

                  if (productCubit.sizes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: productCubit.sizes.map((s) {
                          final selected = s.sizeId == productCubit.selectedSizeId;
                          return ChoiceChip(
                            label: Text(s.size),
                            selected: selected,
                            onSelected: (_) => productCubit.selectSize(s.sizeId),
                            selectedColor: colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: selected
                                  ? colorScheme.secondary
                                  : colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ), // Lề trái phải để không sát mép màn hình
                    child: Row(
                      children: [
                        Container(
                          height: 45,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Nút Giảm
                              SizedBox(
                                width: 36,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: canAdjustQuantity
                                      ? () => productCubit.updateQuantity(-1)
                                      : null,
                                  icon: const Icon(Icons.remove, size: 16),
                                  color: Colors.black54,
                                ),
                              ),

                              VerticalDivider(
                                width: 1,
                                color: Colors.grey.shade300,
                                indent: 8,
                                endIndent: 8,
                              ),

                              // Số lượng
                              Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  productCubit.quantity.toString(),
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                              VerticalDivider(
                                width: 1,
                                color: Colors.grey.shade300,
                                indent: 8,
                                endIndent: 8,
                              ),

                              // Nút Tăng
                              SizedBox(
                                width: 36,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: canAdjustQuantity
                                      ? () => productCubit.updateQuantity(1)
                                      : null,
                                  icon: const Icon(Icons.add, size: 16),
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            productCubit.isStockLoading
                                ? "Đang kiểm tra tồn kho..."
                                : availableQuantity == null
                                ? "Chưa tải được tồn kho"
                                : "Còn $availableQuantity sản phẩm",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildReviewSection(
                    context: context,
                    product: p,
                    textTheme: textTheme,
                    colorScheme: colorScheme,
                  ),

                  _buildRelatedProductsSection(
                    context: context,
                    product: p,
                    textTheme: textTheme,
                    colorScheme: colorScheme,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      // Bottom Action Bar - Nút mua hàng cố định phía dưới
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.onPrimary,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: productDetail == null || !productDetail.isActive
                    ? null
                    : () => _openHelmetDesigner(
                        p,
                        mainUrl ?? p.pickPrimaryImageUrl(productCubit.selectedColorId),
                        productDetail,
                        productCubit.quantity,
                      ),
                // icon: const Icon(Icons.design_services_outlined),
                label: const Text(
                  "THÊM STICKER",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 7,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onPrimary,
                  disabledBackgroundColor: colorScheme.secondary.withOpacity(
                    0.92,
                  ),
                  disabledForegroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: canAddToCart
                    ? () async {
                        final selectedDetail = productDetail;

                        if (widget.onAddToCart != null) {
                          widget.onAddToCart!(p, selectedDetail, productCubit.quantity);
                        } else {
                          await context.read<CartCubit>().addToCart(
                            productDetailId: selectedDetail.id,
                            quantity: productCubit.quantity,
                          );
                          await CartDrawer.show(
                            context,
                            productDetailId: selectedDetail.id,
                          );
                        }
                      }
                    : null,
                child: Text(
                  isInactive
                      ? "NGỪNG BÁN"
                      : isOutOfStock
                      ? "TẠM HẾT HÀNG"
                      : "THÊM VÀO GIỎ HÀNG",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRelatedProductsSection({
    required BuildContext context,
    required Product product,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    if (_isRelatedProductsLoading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: AppLogoLoader(size: 16, strokeWidth: 1.8),
              ),
              SizedBox(width: 12),
              Expanded(child: Text("Đang tải sản phẩm tương tự...")),
            ],
          ),
        ),
      );
    }

    if (_relatedProductsError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.error.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Không tải được sản phẩm tương tự",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _relatedProductsError!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _loadRelatedProducts(product),
                icon: const Icon(Icons.refresh),
                label: const Text("Thử lại"),
              ),
            ],
          ),
        ),
      );
    }

    if (_relatedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
      child: CategoryProductSection(
        title: "Sản phẩm tương tự",
        products: _relatedProducts,
        onSeeMore: () =>
            context.go('/products/categories/${product.categoryId}'),
        onProductTap: (relatedProduct) async {
          await context.push('/products/${relatedProduct.id}');
          if (!mounted) return;
          await _loadPageData();
        },
        onAddToCart:
            (Product relatedProduct, ProductDetail detail, int quantity) async {
              await context.read<CartCubit>().addToCart(
                productDetailId: detail.id,
                quantity: quantity,
              );
              await CartDrawer.show(context, productDetailId: detail.id);
            },
      ),
    );
  }

  Widget _buildReviewSection({
    required BuildContext context,
    required Product product,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    final data = _evaluatePreview;

    if (_isEvaluateLoading && data == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: AppLogoLoader(size: 16, strokeWidth: 1.8),
              ),
              SizedBox(width: 12),
              Expanded(child: Text("Đang tải đánh giá sản phẩm...")),
            ],
          ),
        ),
      );
    }

    if (_evaluateError != null && data == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.error.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Không tải được đánh giá",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _evaluateError!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loadEvaluatePreview,
                icon: const Icon(Icons.refresh),
                label: const Text("Thử lại"),
              ),
            ],
          ),
        ),
      );
    }

    final totalEvaluates = data?.summary.totalEvaluates ?? 0;
    if (data == null || totalEvaluates == 0) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(Icons.reviews_outlined, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Chưa có đánh giá cho sản phẩm này",
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final previewItems = data.items.take(2).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _showAllReviewsSheet(product),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      data.summary.averageRate.toStringAsFixed(1),
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Đánh giá sản phẩm (${data.summary.totalEvaluates})",
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colorScheme.outline),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildReviewSummaryCard(
              data: data,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 14),
            ...List.generate(previewItems.length, (index) {
              final item = previewItems[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == previewItems.length - 1 ? 0 : 12,
                ),
                child: _buildReviewCard(
                  item: item,
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                ),
              );
            }),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _showAllReviewsSheet(product),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Xem tất cả đánh giá",
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: colorScheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSummaryCard({
    required ProductEvaluatePage data,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    final rateMap = {
      for (final rate in data.summary.rateCounts) rate.star: rate.count,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tóm tắt đánh giá sản phẩm",
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if ((data.summary.summaryText ?? "").trim().isNotEmpty)
            Text(
              data.summary.summaryText!,
              style: textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          if ((data.summary.summaryText ?? "").trim().isEmpty)
            Text(
              "Sản phẩm có ${data.summary.totalEvaluates} đánh giá, ${data.summary.totalWithImages} đánh giá có hình ảnh.",
              style: textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(5, (i) {
              final star = 5 - i;
              final count = rateMap[star] ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Text(
                  "$star★ ($count)",
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required EvaluateItem item,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
    bool compact = true,
  }) {
    final evaluaterName =
        item.evaluaterNameMasked ?? item.evaluaterName ?? "Khách hàng";
    final variantText = item.matchedVariants.isNotEmpty
        ? item.matchedVariants.join(" | ")
        : null;
    final content = (item.content ?? "").trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.surfaceVariant,
                child: Icon(
                  Icons.person_outline,
                  size: 18,
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  evaluaterName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                _formatReviewDate(item.createdAt),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStarRow(item.rate),
          if (variantText != null) ...[
            const SizedBox(height: 6),
            Text(
              "Phân loại: $variantText",
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              content,
              maxLines: compact ? 3 : null,
              overflow: compact ? TextOverflow.ellipsis : null,
              style: textTheme.bodyMedium?.copyWith(
                height: 1.3,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (item.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: compact ? 86 : 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: item.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final img = item.images[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: CachedNetworkImage(
                        imageUrl: img.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            _imagePlaceholder(colorScheme),
                        errorWidget: (context, url, error) =>
                            _imagePlaceholder(colorScheme),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRow(int rate) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rate ? Icons.star_rounded : Icons.star_border_rounded,
          size: 18,
          color: index < rate ? Colors.amber : Colors.grey.shade400,
        );
      }),
    );
  }

  Future<void> _showAllReviewsSheet(Product product) async {
    final future = _fetchProductEvaluates(perPage: 50);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final textTheme = Theme.of(sheetContext).textTheme;
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.86,
            child: FutureBuilder<Either<Failure, ProductEvaluatePage>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: AppLogoLoader(size: 64, strokeWidth: 3.5),
                  );
                }

                final data = snapshot.data?.fold((_) => null, (page) => page);
                if (data == null) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          "Không tải được danh sách đánh giá",
                          style: textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Đánh giá ${product.name}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSecondary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _buildReviewSummaryCard(
                        data: data,
                        textTheme: textTheme,
                        colorScheme: colorScheme,
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: data.items.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index == data.items.length) {
                            final remain = data.total - data.items.length;
                            if (remain <= 0) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.all(12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant.withOpacity(
                                  0.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Đang hiển thị ${data.items.length}/${data.total} đánh giá. Có thể bổ sung phân trang sau.",
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall,
                              ),
                            );
                          }
                          return _buildReviewCard(
                            item: data.items[index],
                            textTheme: textTheme,
                            colorScheme: colorScheme,
                            compact: false,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatReviewDate(DateTime? date) {
    if (date == null) return "";
    final d = date.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return "$dd/$mm/${d.year}";
  }

  Widget _imagePlaceholder(ColorScheme colorScheme) => Container(
    color: colorScheme.surfaceVariant,
    alignment: Alignment.center,
    child: Icon(
      Icons.image_not_supported_outlined,
      size: 48,
      color: colorScheme.outline,
    ),
  );

  static String? _thumbForColor({
    required Product product,
    required int colorId,
  }) {
    return product.pickPrimaryImageUrl(colorId);
  }
}

class _ProductImageGallery extends StatefulWidget {
  final List<ProductImage> images;
  final int? selectedColorId;
  final ColorScheme colorScheme;
  final ValueChanged<int> onPageChanged;

  const _ProductImageGallery({
    required this.images,
    required this.selectedColorId,
    required this.colorScheme,
    required this.onPageChanged,
  });

  @override
  State<_ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<_ProductImageGallery> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant _ProductImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedColorId != oldWidget.selectedColorId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int nextIndex) {
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return _galleryPlaceholder(widget.colorScheme);

    final currentIndex = _pageController.hasClients
        ? (_pageController.page?.round() ?? 0)
        : 0;
    final canGoPrev = currentIndex > 0;
    final canGoNext = currentIndex < widget.images.length - 1;

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.images.length,
          onPageChanged: widget.onPageChanged,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: CachedNetworkImage(
                imageUrl: widget.images[index].url,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    _galleryPlaceholder(widget.colorScheme),
                errorWidget: (context, url, error) =>
                    _galleryPlaceholder(widget.colorScheme),
              ),
            );
          },
        ),
        _buildArrow(
          isVisible: canGoPrev,
          alignment: Alignment.centerLeft,
          icon: Icons.chevron_left,
          onTap: () => _goTo(currentIndex - 1),
        ),
        _buildArrow(
          isVisible: canGoNext,
          alignment: Alignment.centerRight,
          icon: Icons.chevron_right,
          onTap: () => _goTo(currentIndex + 1),
        ),
      ],
    );
  }

  Widget _buildArrow({
    required bool isVisible,
    required Alignment alignment,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: alignment == Alignment.centerLeft ? 12 : null,
      right: alignment == Alignment.centerRight ? 12 : null,
      top: 0,
      bottom: 0,
      child: Center(
        child: IgnorePointer(
          ignoring: !isVisible,
          child: AnimatedOpacity(
            opacity: isVisible ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: ArrowButton(icon: icon, onTap: onTap),
          ),
        ),
      ),
    );
  }
}

Widget _galleryPlaceholder(ColorScheme colorScheme) => Container(
  color: colorScheme.surfaceVariant,
  alignment: Alignment.center,
  child: SizedBox(
    width: 26, // Bạn có thể chỉnh kích thước vòng xoay
    height: 26,
    child: CircularProgressIndicator(
      strokeWidth: 3.0, // Độ dày của vòng xoay
      color: colorScheme.primary,
    ),
  ),
);

class _GalleryProgressIndicator extends StatelessWidget {
  final int itemCount;
  final int activeIndex;
  final ColorScheme colorScheme;

  const _GalleryProgressIndicator({
    required this.itemCount,
    required this.activeIndex,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 1) return const SizedBox.shrink();

    final safeIndex = activeIndex.clamp(0, itemCount - 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isActive = index == safeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 18 : 12,
          height: 4,
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.onSurface
                : colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _ProductCartAction extends StatelessWidget {
  const _ProductCartAction();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Selector<CartCubit, int>(
      selector: (_, cubit) => cubit.cartBadgeCount,
      builder: (context, count, _) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: "Giỏ hàng",
                onPressed: () => context.push("/cart"),
                icon: const Icon(Icons.shopping_cart_outlined),
              ),
              if (count > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: colorScheme.onError,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      count > 99 ? "99+" : "$count",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
