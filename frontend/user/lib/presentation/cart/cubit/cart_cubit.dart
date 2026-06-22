import 'package:b2205946_duonghuuluan_luanvan/presentation/cart/cubit/cart_state.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/cart/add_to_cart_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/cart/get_cart_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/cart/remove_from_cart_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/cart/update_cart_detail_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/discount/get_discounts_for_cart_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/product/get_products_usecase.dart';
import 'package:bloc/bloc.dart';

class CartCubit extends Cubit<CartState> {
  final GetCartUseCase _getCart;
  final AddToCartUseCase _addToCart;
  final UpdateCartDetailUseCase _updateCartDetail;
  final RemoveFromCartUseCase _removeFromCart;
  final GetProductsUseCase _getProducts;
  final GetDiscountsForCartUseCase _getDiscountsForCart;

  CartCubit(
    this._getCart,
    this._addToCart,
    this._updateCartDetail,
    this._removeFromCart,
    this._getProducts,
    this._getDiscountsForCart,
  ) : super(const CartState());

  Map<int, Product> _productByDetailid = {};
  Set<int> _lastDiscountCategoryIds = {};

  int get cartBadgeCount =>
      state.cartDetails.fold(0, (total, item) => total + item.quantity);

  bool get canCheckoutCart => state.cart?.canCheckout ?? true;
  bool get hasInvalidItems => state.cartDetails.any((e) => !e.canCheckout);

  Product? productForDetail(int detailId) => _productByDetailid[detailId];
  int? categoryIdForDetail(int detailId) =>
      _productByDetailid[detailId]?.categoryId;

  List<CartDetail> validSelectedItems(Iterable<int> selectedIds) {
    return state.cartDetails
        .where((d) => selectedIds.contains(d.id) && d.canCheckout)
        .toList();
  }

  bool selectionHasInvalidItems(Iterable<int> selectedIds) {
    return state.cartDetails
        .where((d) => selectedIds.contains(d.id))
        .any((d) => !d.canCheckout);
  }

  Future<void> _loadProductMap() async {
    if (_productByDetailid.isNotEmpty) return;
    final result = await _getProducts();
    result.fold(
      (_) => null,
      (products) {
        final map = <int, Product>{};
        for (final product in products) {
          for (final detail in product.productDetails) {
            map[detail.id] = product;
          }
        }
        _productByDetailid = map;
      },
    );
  }

  void _resetDiscountCache({bool clearDiscounts = false}) {
    _lastDiscountCategoryIds = {};
    if (clearDiscounts) {
      emit(
        state.copyWith(
          discounts: const [],
          isDiscountLoading: false,
          discountError: null,
        ),
      );
    }
  }

  double _calculateCartTotal(List<CartDetail> details) {
    return details.fold(0, (sum, item) => sum + item.lineTotal);
  }

  Future<void> fetchDiscountsForCategories(List<int> categoryIds) async {
    final normalized = categoryIds.toSet();
    if (normalized.isEmpty) {
      emit(
        state.copyWith(
          discounts: const [],
          isDiscountLoading: false,
          discountError: null,
        ),
      );
      return;
    }
    if (_lastDiscountCategoryIds.length == normalized.length &&
        _lastDiscountCategoryIds.containsAll(normalized))
      return;
    _lastDiscountCategoryIds = normalized;
    emit(state.copyWith(isDiscountLoading: true, discountError: null));
    final discountResult = await _getDiscountsForCart(
      categoryIds: normalized.toList(),
    );
    discountResult.fold(
      (failure) => emit(
        state.copyWith(
          isDiscountLoading: false,
          discountError: failure.message,
          discounts: const [],
        ),
      ),
      (discounts) => emit(state.copyWith(isDiscountLoading: false, discounts: discounts)),
    );
  }

  Future<void> fetchCart() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await _getCart();
    await result.fold(
      (failure) async => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (cart) async {
        await _loadProductMap();
        _resetDiscountCache(clearDiscounts: true);
        emit(state.copyWith(isLoading: false, cart: cart));
      },
    );
  }

  Future<void> addToCart({
    required int productDetailId,
    int quantity = 1,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await _addToCart(
      productDetailId: productDetailId,
      quantity: quantity,
    );
    await result.fold(
      (failure) async => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (cart) async {
        await _loadProductMap();
        _resetDiscountCache(clearDiscounts: true);
        emit(state.copyWith(isLoading: false, cart: cart));
      },
    );
  }

  Future<void> updateCartDetail({
    required int cartDetailId,
    required int newQuantity,
  }) async {
    final previousCart = state.cart;
    final currentCart = state.cart;
    if (currentCart != null) {
      var hasChange = false;
      final updatedDetails = currentCart.cartDetails.map((detail) {
        if (detail.id != cartDetailId) return detail;
        hasChange = detail.quantity != newQuantity;
        return detail.copyWith(quantity: newQuantity);
      }).toList();
      if (!hasChange) return;
      emit(
        state.copyWith(
          cart: currentCart.copyWith(
            cartDetails: updatedDetails,
            totalPrice: _calculateCartTotal(updatedDetails),
          ),
        ),
      );
    }
    emit(state.copyWith(isLoading: true, errorMessage: null));
    _resetDiscountCache(clearDiscounts: true);
    final result = await _updateCartDetail(
      cartDetailId: cartDetailId,
      newQuantity: newQuantity,
    );
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
          cart: previousCart,
        ),
      ),
      (cart) async {
        await _loadProductMap();
        _resetDiscountCache(clearDiscounts: true);
        emit(state.copyWith(isLoading: false, cart: cart));
      },
    );
  }

  Future<void> deleteCartDetail({required int cartDetailId}) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final removeResult = await _removeFromCart(cartDetailId: cartDetailId);
    await removeResult.fold(
      (failure) async => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (_) async {
        final cartResult = await _getCart();
        await cartResult.fold(
          (failure) async => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
          (cart) async {
            await _loadProductMap();
            _resetDiscountCache(clearDiscounts: true);
            emit(state.copyWith(isLoading: false, cart: cart));
          },
        );
      },
    );
  }

  String statusLabel(CartDetail item) {
    switch (item.cartStatus) {
      case "inactive":
        return "Ngừng bán";
      case "out_of_stock":
        return "Hết hàng";
      case "insufficient_stock":
        return "Vượt tồn kho";
      default:
        return "Còn hàng";
    }
  }
}
