import 'package:b2205946_duonghuuluan_luanvan/domain/entity/cart/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/discount/discount.dart';
import 'package:equatable/equatable.dart';

class CartState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final Cart? cart;
  final List<Discount> discounts;
  final bool isDiscountLoading;
  final String? discountError;

  const CartState({
    this.isLoading = false,
    this.errorMessage,
    this.cart,
    this.discounts = const [],
    this.isDiscountLoading = false,
    this.discountError,
  });

  List<CartDetail> get cartDetails => cart?.cartDetails ?? [];
  double get totalPrice => cart?.totalPrice ?? 0;

  CartState copyWith({
    bool? isLoading,
    String? errorMessage,
    Cart? cart,
    List<Discount>? discounts,
    bool? isDiscountLoading,
    String? discountError,
    bool clearCart = false,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      cart: clearCart ? null : (cart ?? this.cart),
      discounts: discounts ?? this.discounts,
      isDiscountLoading: isDiscountLoading ?? this.isDiscountLoading,
      discountError: discountError,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    errorMessage,
    cart,
    discounts,
    isDiscountLoading,
    discountError,
  ];
}
