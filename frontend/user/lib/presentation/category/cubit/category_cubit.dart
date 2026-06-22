import 'package:b2205946_duonghuuluan_luanvan/presentation/category/cubit/category_state.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/category/category.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/category/get_categories_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/category/get_category_by_id_usecase.dart';
import 'package:bloc/bloc.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final GetCategoriesUseCase _getCategories;
  final GetCategoryByIdUseCase _getCategoryById;

  CategoryCubit(this._getCategories, this._getCategoryById)
    : super(const CategoryState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await _getCategories();
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (categories) => emit(state.copyWith(isLoading: false, categories: categories)),
    );
  }

  Future<Category?> getById(int id) async {
    final result = await _getCategoryById(id);
    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return null;
      },
      (category) => category,
    );
  }
}
