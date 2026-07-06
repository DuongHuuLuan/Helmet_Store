import 'package:b2205946_duonghuuluan_luanvan/domain/entity/product/product.dart';
import 'package:equatable/equatable.dart';

class ProductState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<Product> products;
  final Product? product;

  const ProductState({
    this.isLoading = false,
    this.errorMessage,
    this.products = const [],
    this.product,
  });

  ProductState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Product>? products,
    Product? product,
    bool clearProduct = false,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      products: products ?? this.products,
      product: clearProduct ? null : (product ?? this.product),
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, products, product];
}
