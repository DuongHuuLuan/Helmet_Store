import 'package:b2205946_duonghuuluan_luanvan/domain/entity/category/category.dart';
import 'package:equatable/equatable.dart';

class CategoryState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<Category> categories;

  const CategoryState({
    this.isLoading = false,
    this.errorMessage,
    this.categories = const [],
  });

  CategoryState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Category>? categories,
  }) {
    return CategoryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      categories: categories ?? this.categories,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, categories];
}
