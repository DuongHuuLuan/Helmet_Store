import 'package:b2205946_duonghuuluan_luanvan/core/widgets/app_logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:b2205946_duonghuuluan_luanvan/injection_container.dart' as di;
import 'package:b2205946_duonghuuluan_luanvan/core/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/evaluate/evaluate.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_extension.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_detail.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/evaluate/get_product_evaluates_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/warehouse/get_total_stock_usecase.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final void Function(
    Product product,
    ProductDetail productDetail,
    int quantity,
  )?
  onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  static const int _maxColorThumbs = 3;
  static final Map<int, ProductEvaluateSummary> _evaluateSummaryCache = {};
  static final Map<int, Future<ProductEvaluateSummary?>> _evaluateRequests = {};

  // Animation variables cho hiệu ứng Pulse (Phóng to/thu nhỏ)
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _floatAnimation;

  int? _selectedColorId;
  int? _selectedSizeId;
  int? _availableQuantity;
  ProductEvaluateSummary? _evaluateSummary;
  bool _isStockLoading = false;

  Product get _p => widget.product;

  // ====== UI data ======
  List<ProductDetail> get _activeDetails =>
      _p.productDetails.where((e) => e.isActive).toList();

  List<ProductDetail> get _colors => _p.uniqueColors.where((color) {
    return _activeDetails.any((d) => d.colorId == color.colorId);
  }).toList();

  List<ProductDetail> get _sizes => _p
      .getUniqueSizesByColor(_selectedColorId)
      .where((e) => e.isActive)
      .toList();

  ProductDetail? get _selectedProductDetail {
    final detail = _p.findProductDetail(_selectedColorId, _selectedSizeId);
    if (detail == null || !detail.isActive) return null;
    return detail;
  }

  List<_ColorThumb> get _colorThumbs {
    if (_colors.isEmpty) return [];
    final result = <_ColorThumb>[];
    for (final c in _colors) {
      final primaryUrl = _p.pickPrimaryImageUrl(c.colorId);
      if (primaryUrl == null || primaryUrl.isEmpty) continue;
      result.add(
        _ColorThumb(colorId: c.colorId, label: c.colorName, url: primaryUrl),
      );
    }
    return result;
  }

  @override
  void initState() {
    super.initState();

    // Khởi tạo Controller cho hiệu ứng phóng to thu nhỏ
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Tween từ kích thước gốc (1.0) lên 1.2 (lớn hơn 20%)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Hiệu ứng nhấp nhô lên xuống cho icon "nhiều màu"
    _floatAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: const Offset(0, -0.12),
        ).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );

    // Chạy lặp lại liên tục và đảo chiều (reverse) để tạo hiệu ứng nhịp tim
    _pulseController.repeat(reverse: true);

    _syncProductState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStock();
      _loadEvaluateSummary();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id == widget.product.id) return;

    _syncProductState();
    final productId = widget.product.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.product.id != productId) return;
      _loadStock();
      _loadEvaluateSummary();
    });
  }

  // Hàm reset lại hiệu ứng khi tương tác nếu cần
  void _resetPulse() {
    _pulseController.forward(from: 0.0);
    _pulseController.repeat(reverse: true);
  }

  void _selectColor(int colorId) {
    setState(() {
      _selectedColorId = colorId;
      final sizes = _p.getUniqueSizesByColor(colorId);
      final stillOk = sizes.any((s) => s.sizeId == _selectedSizeId);
      if (!stillOk) {
        _selectedSizeId = sizes.isNotEmpty ? sizes.first.sizeId : null;
      }
    });
    _resetPulse();
    _loadStock();
  }

  void _selectSize(int sizeId) {
    setState(() => _selectedSizeId = sizeId);
    _resetPulse();
    _loadStock();
  }

  void _syncProductState() {
    _availableQuantity = null;
    _selectedColorId = null;
    _selectedSizeId = null;

    if (_activeDetails.isNotEmpty) {
      final preferredColors = _colors;
      _selectedColorId = preferredColors.isNotEmpty
          ? preferredColors.first.colorId
          : _activeDetails.first.colorId;

      final preferredSizes = _sizes;
      _selectedSizeId = preferredSizes.isNotEmpty
          ? preferredSizes.first.sizeId
          : _activeDetails.first.sizeId;
    }

    _evaluateSummary = _evaluateSummaryCache[_p.id];
  }

  Future<void> _loadStock() async {
    final productId = _p.id;
    final detail = _selectedProductDetail;

    if (detail == null) {
      if (!mounted) return;
      setState(() {
        _availableQuantity = null;
        _isStockLoading = false;
      });
      return;
    }

    setState(() => _isStockLoading = true);

    final result = await di.getIt<GetTotalStockUseCase>()(
      productId: productId,
      colorId: detail.colorId,
      sizeId: detail.sizeId,
    );
    result.fold(
      (_) {
        if (mounted) setState(() => _isStockLoading = false);
      },
      (stock) {
        if (!mounted || widget.product.id != productId) return;
        setState(() {
          _availableQuantity = stock.quantity;
          _isStockLoading = false;
        });
      },
    );
  }

  Future<void> _loadEvaluateSummary() async {
    final productId = _p.id;
    if (_evaluateSummaryCache.containsKey(productId)) {
      if (!mounted || widget.product.id != productId) return;
      setState(() => _evaluateSummary = _evaluateSummaryCache[productId]);
      return;
    }

    final summary = await _evaluateRequests.putIfAbsent(productId, () async {
      final result = await di.getIt<GetProductEvaluatesUseCase>()(productId: productId, perPage: 1);
      return result.fold(
        (_) {
          _evaluateRequests.remove(productId);
          return null as ProductEvaluateSummary?;
        },
        (page) {
          _evaluateSummaryCache[productId] = page.summary;
          _evaluateRequests.remove(productId);
          return page.summary;
        },
      );
    });

    if (!mounted || summary == null || widget.product.id != productId) return;
    setState(() => _evaluateSummary = summary);
  }

  @override
  Widget build(BuildContext context) {
    final productDetail = _selectedProductDetail;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final mainUrl = _p.pickPrimaryImageUrl(_selectedColorId);

    final isInactive = productDetail == null;
    final inStock =
        !isInactive && _availableQuantity != null && _availableQuantity! > 0;
    final priceText = productDetail != null
        ? productDetail.price.toVnd()
        : "Liên hệ";

    final showRating =
        _evaluateSummary != null && _evaluateSummary!.totalEvaluates > 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.onPrimary,
          borderRadius: BorderRadius.circular(14),
          // border: Border.all(color: colorScheme.outlineVariant, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10, // Độ nhòe của bóng
              spreadRadius: 0, // Độ lan rộng của bóng
              offset: const Offset(0, 4), // Bóng đổ xuống dưới 4 pixel
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),

                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: mainUrl != null
                          ? CachedNetworkImage(
                              imageUrl: mainUrl,
                              fit: BoxFit.contain,
                              placeholder: (context, url) =>
                                  _imageLoading(colorScheme),
                              errorWidget: (context, url, error) =>
                                  _imagePlaceholder(colorScheme),
                            )
                          : _imagePlaceholder(colorScheme),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _isStockLoading
                      ? _buildLoadingIndicator(colorScheme)
                      : ScaleTransition(
                          // Chỉ phóng to nếu còn hàng (inStock)
                          scale: inStock
                              ? _scaleAnimation
                              : const AlwaysStoppedAnimation(1.0),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: (isInactive || !inStock)
                                  ? null
                                  : () => widget.onAddToCart?.call(
                                      _p,
                                      productDetail,
                                      1,
                                    ),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: inStock
                                      ? colorScheme.secondary.withOpacity(0.9)
                                      : Colors.grey.withOpacity(0.9),

                                  shape: BoxShape.circle,

                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),

                                      blurRadius: 4,

                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  inStock
                                      ? Icons.add_shopping_cart
                                      : Icons.remove_shopping_cart,
                                  size: 25,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),

                if (!_isStockLoading && (isInactive || !inStock))
                  _buildStatusOverlay(isInactive: isInactive),
              ],
            ),

            // Color Thumbnails
            if (_colorThumbs.isNotEmpty)
              _buildSectionPadding(
                child: SizedBox(
                  height: 33,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colorThumbs.length > _maxColorThumbs
                        ? _maxColorThumbs + 1
                        : _colorThumbs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final hasMore = _colorThumbs.length > _maxColorThumbs;
                      if (hasMore && i == _maxColorThumbs) {
                        return _buildMoreColorsIndicator(colorScheme);
                      }

                      final t = _colorThumbs[i];
                      final active = t.colorId == _selectedColorId;
                      return InkWell(
                        onTap: () => _selectColor(t.colorId),
                        child: Container(
                          width: 33,
                          height: 33,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: active
                                  ? colorScheme.secondary
                                  : colorScheme.outline,
                              width: active ? 1.5 : 0.5,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: t.url,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Size Selection
            if (_sizes.isNotEmpty)
              _buildSectionPadding(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _sizes.map((v) {
                    final selected = v.sizeId == _selectedSizeId;
                    return InkWell(
                      onTap: () => _selectSize(v.sizeId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? colorScheme.secondary
                                : colorScheme.outline,
                            width: selected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Text(
                          v.size,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? colorScheme.secondary
                                : colorScheme.onSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Product Name
            _buildSectionPadding(
              child: Text(
                _p.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSecondary,
                ),
              ),
            ),

            // Price and Rating
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      priceText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                  if (showRating)
                    _ProductRatingInline(summary: _evaluateSummary!),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ====== Các Widget phụ trợ ======

  Widget _buildSectionPadding({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: child,
    );
  }

  Widget _buildLoadingIndicator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      width: 41,
      height: 41,
      decoration: BoxDecoration(
        color: colorScheme.secondary.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: AppLogoLoader(size: 20, strokeWidth: 2),
    );
  }

  Widget _buildStatusOverlay({required bool isInactive}) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.black54,
            child: Text(
              isInactive ? "NGỪNG BÁN" : "HẾT HÀNG",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreColorsIndicator(ColorScheme colorScheme) {
    return SlideTransition(
      position: _floatAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 33,
            height: 33,
            child: Center(
              child: RotatedBox(
                quarterTurns: 2, // xoay 2 lần 90 độ
                child: Icon(
                  Icons.change_history,
                  size: 25,
                  color: colorScheme.onSecondary.withOpacity(0.75),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme colorScheme) => Container(
    color: colorScheme.surfaceVariant,
    alignment: Alignment.center,
    child: Icon(Icons.image, size: 40, color: colorScheme.outline),
  );

  Widget _imageLoading(ColorScheme colorScheme) => Container(
    color: colorScheme.surfaceVariant,
    alignment: Alignment.center,
    child: const CircularProgressIndicator(strokeWidth: 2),
  );
}

class _ProductRatingInline extends StatelessWidget {
  final ProductEvaluateSummary summary;
  const _ProductRatingInline({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
          const SizedBox(width: 2),
          Text(
            summary.averageRate.toStringAsFixed(1),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: colorScheme.onSecondary,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            "(${summary.totalEvaluates})",
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: colorScheme.onSecondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorThumb {
  final int colorId;
  final String label;
  final String url;
  _ColorThumb({required this.colorId, required this.label, required this.url});
}
