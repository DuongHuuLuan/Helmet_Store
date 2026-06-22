import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_detail.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_extension.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product_image.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/product/get_product_detail_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/product/get_products_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/warehouse/get_total_stock_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/product/cubit/product_state.dart';
import 'package:bloc/bloc.dart';

class ProductCubit extends Cubit<ProductState> {
  final GetProductsUseCase _getProducts;
  final GetProductDetailUseCase _getProductDetail;
  final GetTotalStockUseCase _getTotalStock;

  ProductCubit(this._getProducts, this._getProductDetail, this._getTotalStock)
    : super(const ProductState());

  static const int _defaultPerPage = 8;
  int _page = 1;
  int _perPage = _defaultPerPage;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int? _currentCategoryId;
  String _currentKeyword = '';

  int? _selectedColorId;
  int? _selectedSizeId;
  int _imgIndex = 0;
  int _quantity = 1;
  int? _availableQuantity;
  bool _stockLoading = false;

  int? get selectedColorId => _selectedColorId;

  int? get selectedSizeId => _selectedSizeId;

  int get imgIndex => _imgIndex;

  int get quantity => _quantity;

  int? get availableQuantity => _availableQuantity;

  bool get isStockLoading => _stockLoading;

  bool get hasMore => _hasMore;

  bool get isLoadingMore => _isLoadingMore;

  int get perPage => _perPage;

  String get currentKeyword => _currentKeyword;

  bool get hasActiveKeyword => _currentKeyword.isNotEmpty;

  List<ProductDetail> get activeProductDetails =>
      state.product?.productDetails
          .where((ProductDetail e) => e.isActive)
          .toList() ??
      const [];

  bool get hasAnyActiveDetails => activeProductDetails.isNotEmpty;

  List<ProductDetail> get colors {
    final p = state.product;
    if (p == null) return const [];
    return p.uniqueColors
        .where(
          (dynamic c) =>
              c is ProductDetail &&
              activeProductDetails.any(
                (ProductDetail d) => d.colorId == c.colorId,
              ),
        )
        .cast<ProductDetail>()
        .toList();
  }

  List<ProductDetail> get sizes {
    final p = state.product;
    if (p == null) return const [];
    return p
        .getUniqueSizesByColor(_selectedColorId)
        .where((ProductDetail e) => e.isActive)
        .toList();
  }

  ProductDetail? get selectedProductDetail {
    final p = state.product;
    if (p == null) return null;
    final detail = p.findProductDetail(_selectedColorId, _selectedSizeId);
    if (detail == null || !detail.isActive) return null;
    return detail;
  }

  List<ProductImage> get displayProductImages =>
      state.product?.galleryImagesForColor(_selectedColorId) ?? const [];

  bool get isSelectedDetailsInactive {
    final p = state.product;
    if (p == null) return false;
    final detail = p.findProductDetail(_selectedColorId, _selectedSizeId);
    return detail == null || !detail.isActive;
  }

  Map<int, List<Product>> get productsByCategory {
    final map = <int, List<Product>>{};
    for (final p in state.products) {
      map.putIfAbsent(p.categoryId, () => []).add(p);
    }
    return map;
  }

  List<Product> _filterProductsForUser(List<Product> input) {
    for (final p in input) {}
    final output = input
        .where((p) => p.productDetails.any((d) => d.isActive))
        .toList();
    return output;
  }

  Future<void> getAllProduct({
    int? categoryId,
    int? page,
    int? perPage,
    String? keyword,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    _isLoadingMore = false;
    _currentCategoryId = categoryId;
    _currentKeyword = keyword?.trim() ?? '';
    final result = await _getProducts(
      categoryId: categoryId,
      page: page,
      perPage: perPage,
      keyword: _currentKeyword.isEmpty ? null : _currentKeyword,
    );
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (list) {
        final filtered = _filterProductsForUser(list);
        if (page != null || perPage != null) {
          _page = page ?? 1;
          _perPage = perPage ?? _perPage;
          _hasMore = list.length >= _perPage;
        } else {
          _page = 1;
          _hasMore = false;
        }
        emit(state.copyWith(isLoading: false, products: filtered));
      },
    );
  }

  Future<void> loadInitialPaged({
    int? categoryId,
    int? perPage,
    String? keyword,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    _currentCategoryId = categoryId;
    _currentKeyword = keyword?.trim() ?? '';
    _page = 1;
    _perPage = perPage ?? _defaultPerPage;
    _hasMore = true;
    _isLoadingMore = false;
    final result = await _getProducts(
      categoryId: categoryId,
      page: _page,
      perPage: _perPage,
      keyword: _currentKeyword.isEmpty ? null : _currentKeyword,
    );
    result.fold(
      (failure) {
        _hasMore = false;
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
            products: const [],
          ),
        );
      },
      (list) {
        final filtered = _filterProductsForUser(list);
        if (list.length < _perPage) _hasMore = false;
        emit(state.copyWith(isLoading: false, products: filtered));
      },
    );
  }

  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    emit(state.copyWith());
    final nextPage = _page + 1;
    final result = await _getProducts(
      categoryId: _currentCategoryId,
      page: nextPage,
      perPage: _perPage,
      keyword: _currentKeyword.isEmpty ? null : _currentKeyword,
    );
    result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
      },
      (list) {
        final filtered = _filterProductsForUser(list);
        if (list.isEmpty) {
          _hasMore = false;
        } else {
          final updated = [...state.products, ...filtered];
          _page = nextPage;
          if (list.length < _perPage) _hasMore = false;
          emit(state.copyWith(products: updated));
        }
      },
    );
    _isLoadingMore = false;
    emit(state.copyWith());
  }

  Future<void> productDetail(int id) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await _getProductDetail(id);
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (product) {
        emit(state.copyWith(isLoading: false, product: product));
        _resetSelection();
      },
    );
  }

  void _resetSelection() {
    final active = activeProductDetails;
    if (state.product != null && active.isNotEmpty) {
      final preferredColors = colors;
      _selectedColorId = preferredColors.isNotEmpty
          ? preferredColors.first.colorId
          : active.first.colorId;
      final preferredSizes = sizes;
      _selectedSizeId = preferredSizes.isNotEmpty
          ? preferredSizes.first.sizeId
          : active.first.sizeId;
      _imgIndex = 0;
      _quantity = 1;
      _loadSelectedStock();
      return;
    }
    _selectedColorId = null;
    _selectedSizeId = null;
    _imgIndex = 0;
    _quantity = 1;
    _availableQuantity = null;
    _stockLoading = false;
  }

  void selectColor(int colorId) {
    _selectedColorId = colorId;
    _imgIndex = 0;
    final availableSizes = sizes;
    if (!availableSizes.any((e) => e.sizeId == _selectedSizeId)) {
      _selectedSizeId = availableSizes.isNotEmpty
          ? availableSizes.first.sizeId
          : null;
    }
    _loadSelectedStock();
    emit(state.copyWith());
  }

  void selectSize(int sizeId) {
    _selectedSizeId = sizeId;
    _loadSelectedStock();
    emit(state.copyWith());
  }

  void setImgIndex(int index) {
    final images = displayProductImages;
    if (images.isEmpty) {
      if (_imgIndex == 0) return;
      _imgIndex = 0;
      emit(state.copyWith());
      return;
    }
    final safeIndex = index.clamp(0, images.length - 1);
    if (_imgIndex == safeIndex) return;
    _imgIndex = safeIndex;
    emit(state.copyWith());
  }

  void updateQuantity(int delta) {
    final detail = selectedProductDetail;
    if (detail == null ||
        !detail.isActive ||
        _stockLoading ||
        _availableQuantity == null)
      return;
    final maxStock = _availableQuantity!;
    final newQuantity = _quantity + delta;
    if (maxStock <= 0) {
      if (_quantity != 1) {
        _quantity = 1;
        emit(state.copyWith());
      }
      return;
    }
    if (newQuantity >= 1 && newQuantity <= maxStock) {
      _quantity = newQuantity;
      emit(state.copyWith());
    }
  }

  Future<void> _loadSelectedStock() async {
    final detail = selectedProductDetail;
    if (detail == null || state.product == null) {
      _availableQuantity = null;
      _stockLoading = false;
      return;
    }
    if (!detail.isActive) {
      _availableQuantity = 0;
      _stockLoading = false;
      _quantity = 1;
      emit(state.copyWith());
      return;
    }
    _stockLoading = true;
    emit(state.copyWith());
    final result = await _getTotalStock(
      productId: state.product!.id,
      colorId: detail.colorId,
      sizeId: detail.sizeId,
    );
    result.fold((_) => null, (stock) {
      _availableQuantity = stock.quantity;
      if (_quantity > stock.quantity && stock.quantity > 0)
        _quantity = stock.quantity;
      if (stock.quantity <= 0) _quantity = 1;
    });
    _stockLoading = false;
    emit(state.copyWith());
  }
}
